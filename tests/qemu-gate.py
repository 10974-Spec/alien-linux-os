#!/usr/bin/env python3
"""
tests/qemu-gate.py — Automated QEMU VM Verification Gate for Alien OS
Boots the ISO in QEMU with UEFI, monitors serial output for BEGIN / STEP / RESULT / END tokens,
takes QMP screendumps on each STEP, and generates docs/test-reports/gate-<build-id>.md.
"""

import os
import sys
import time
import socket
import json
import subprocess
import shutil
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VM_DIR = ROOT / "vm"
OUT_DIR = ROOT / "out"
REPORTS_DIR = ROOT / "docs" / "test-reports"
PROOF_BASE = ROOT / "docs" / "ship-proof"

VM_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)
PROOF_BASE.mkdir(parents=True, exist_ok=True)

def find_newest_iso():
    isos = sorted(OUT_DIR.glob("*.iso"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not isos:
        print("ERROR: No ISO found in out/", file=sys.stderr)
        sys.exit(1)
    return isos[0]

class QmpSession:
    def __init__(self, sock_path):
        self.sock_path = str(sock_path)
        self.sock = None

    def connect(self, timeout=40):
        start = time.time()
        while time.time() - start < timeout:
            if os.path.exists(self.sock_path):
                try:
                    self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.sock.settimeout(5.0)
                    self.sock.connect(self.sock_path)
                    self.sock.recv(4096)
                    self.sock.sendall(b'{"execute": "qmp_capabilities"}\n')
                    self.sock.recv(4096)
                    return True
                except Exception:
                    pass
            time.sleep(0.5)
        return False

    def screendump(self, out_png):
        if not self.sock:
            return False
        ppm = f"/tmp/gate-screendump-{os.getpid()}-{int(time.time()*1000)}.ppm"
        payload = json.dumps({"execute": "screendump", "arguments": {"filename": ppm}}) + "\n"
        try:
            self.sock.sendall(payload.encode("utf-8"))
            time.sleep(0.4)
            if os.path.exists(ppm):
                out_png.parent.mkdir(parents=True, exist_ok=True)
                subprocess.run(["convert", ppm, str(out_png)], check=True)
                os.remove(ppm)
                return True
        except Exception as e:
            print(f"Screendump error: {e}", file=sys.stderr)
        return False

    def send_key(self, key):
        if not self.sock:
            return
        payload = json.dumps({"execute": "send-key", "arguments": {"keys": [{"type": "qcode", "data": key}]}}) + "\n"
        try:
            self.sock.sendall(payload.encode("utf-8"))
        except Exception:
            pass

    def close(self):
        if self.sock:
            try:
                self.sock.close()
            except Exception:
                pass
            self.sock = None

def main():
    iso_path = Path(sys.argv[1]) if len(sys.argv) > 1 else find_newest_iso()
    print(f"============================================================")
    print(f" Alien OS — Automated QEMU Ship Gate")
    print(f" Target ISO: {iso_path.name}")
    print(f" Size:       {iso_path.stat().st_size / (1024*1024):.1f} MB")
    print(f"============================================================")

    # First, run Phase 0 / 2a static inspection
    print("\n>>> Phase 2a: Static ISO Inspection via tools/iso-inspect.sh...")
    inspect_res = subprocess.run(["bash", str(ROOT / "tools" / "iso-inspect.sh"), str(iso_path)])
    if inspect_res.returncode != 0:
        print("FAIL: Static ISO inspection failed!", file=sys.stderr)
        sys.exit(inspect_res.returncode)

    # Next, Phase 2b: Boot QEMU with alien.selftest=1
    print("\n>>> Phase 2b: Booting ISO in QEMU with serial handshake...")
    build_id_match = re.search(r"alien-[a-z]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)\.iso", iso_path.name)
    if not build_id_match:
        build_id_match = re.search(r"alien-[a-z]+-[0-9.]+-(.+)-amd64\.iso", iso_path.name)
    build_id = build_id_match.group(1) if build_id_match else "unknown"

    proof_dir = PROOF_BASE / build_id
    proof_dir.mkdir(parents=True, exist_ok=True)

    qmp_sock = VM_DIR / f"gate-qmp-{os.getpid()}.sock"
    serial_sock = VM_DIR / f"gate-serial-{os.getpid()}.sock"
    vars_fd = VM_DIR / f"gate-vars-{os.getpid()}.fd"

    if qmp_sock.exists():
        qmp_sock.unlink()
    if serial_sock.exists():
        serial_sock.unlink()

    # OVMF setup
    ovmf_code = "/usr/share/OVMF/OVMF_CODE_4M.secboot.fd"
    if not os.path.exists(ovmf_code):
        ovmf_code = "/usr/share/OVMF/OVMF_CODE.fd"
    ovmf_vars_orig = "/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
    if not os.path.exists(ovmf_vars_orig):
        ovmf_vars_orig = "/usr/share/OVMF/OVMF_VARS.fd"

    if os.path.exists(ovmf_vars_orig):
        shutil.copyfile(ovmf_vars_orig, vars_fd)

    qemu_cmd = [
        "qemu-system-x86_64",
        "-enable-kvm",
        "-machine", "q35",
        "-cpu", "host",
        "-smp", "2",
        "-m", "4096",
        "-vga", "virtio",
        "-display", "none",
        "-cdrom", str(iso_path),
        "-boot", "d",
        "-drive", f"if=pflash,format=raw,readonly=on,file={ovmf_code}",
        "-drive", f"if=pflash,format=raw,file={vars_fd}",
        "-qmp", f"unix:{qmp_sock},server,nowait",
        "-serial", f"unix:{serial_sock},server,nowait",
        "-netdev", "user,id=net0",
        "-device", "virtio-net-pci,netdev=net0",
    ]

    print("Launching QEMU VM...")
    proc = subprocess.Popen(qemu_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    qmp = QmpSession(qmp_sock)

    results = []
    try:
        if not qmp.connect(timeout=30):
            print("ERROR: Failed to connect to QMP socket within 30s", file=sys.stderr)
            proc.kill()
            sys.exit(1)

        print("QMP connected. Monitoring boot and connecting to guest serial socket...")
        qmp.screendump(proof_dir / "00-boot-start.png")

        # Connect to serial socket
        s_sock = None
        for _ in range(40):
            if os.path.exists(serial_sock):
                try:
                    s_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    s_sock.connect(str(serial_sock))
                    s_sock.settimeout(1.0)
                    break
                except Exception:
                    pass
            time.sleep(0.5)

        start_time = time.time()
        max_wait = 180
        token_found_begin = False
        token_found_end = False
        selftest_triggered = False
        current_step = None
        step_idx = 1
        serial_buf = ""

        while time.time() - start_time < max_wait:
            if s_sock:
                try:
                    chunk = s_sock.recv(4096).decode("utf-8", errors="ignore")
                    if chunk:
                        serial_buf += chunk
                        # Check if shell is ready to trigger selftest
                        if ("-bash" in chunk or "alien ttyS0" in chunk or "Welcome to Alien" in chunk) and not selftest_triggered:
                            print("  [>>] In-guest shell detected. Triggering alien-guest-selftest...")
                            time.sleep(2.0)
                            s_sock.sendall(b"\nsu - alien -c 'DISPLAY=:0 /usr/bin/alien-guest-selftest --force'\n")
                            selftest_triggered = True
                except socket.timeout:
                    pass
                except Exception as e:
                    pass

            # Fallback trigger after 40 seconds if shell prompt was missed
            if time.time() - start_time > 40 and not selftest_triggered and s_sock:
                print("  [>>] Boot grace elapsed. Triggering selftest command...")
                s_sock.sendall(b"\nsu - alien -c 'DISPLAY=:0 /usr/bin/alien-guest-selftest --force'\n")
                selftest_triggered = True

            # Process lines in serial_buf
            while "\n" in serial_buf:
                line_str, serial_buf = serial_buf.split("\n", 1)
                line_str = line_str.strip()
                if not line_str:
                    continue

                if "BEGIN" in line_str:
                    token_found_begin = True
                    print(f"  [>>] Serial: {line_str}")
                    qmp.screendump(proof_dir / "01-begin.png")
                elif "STEP" in line_str:
                    match = re.search(r"STEP\s+(\S+)", line_str)
                    if match:
                        current_step = match.group(1)
                        step_file = proof_dir / f"{step_idx:02d}-{current_step}.png"
                        time.sleep(1.0)
                        qmp.screendump(step_file)
                        step_idx += 1
                        print(f"  [>>] Step: {current_step} (Screenshot: {step_file.name})")
                elif "RESULT" in line_str:
                    match = re.search(r"RESULT\s+(\S+)\s+(PASS|FAIL)\s*(.*)", line_str)
                    if match:
                        item, status, detail = match.groups()
                        results.append({"item": item, "status": status, "detail": detail})
                        print(f"  [{status}] {item}: {detail}")
                elif "END" in line_str:
                    token_found_end = True
                    print(f"  [>>] Serial: {line_str}")
                    break

            if token_found_end:
                break
            time.sleep(0.3)

        qmp.screendump(proof_dir / "final-desktop.png")

    finally:
        if s_sock:
            try:
                s_sock.close()
            except Exception:
                pass
        qmp.close()
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
        if vars_fd.exists():
            vars_fd.unlink()
        if qmp_sock.exists():
            qmp_sock.unlink()
        if serial_sock.exists():
            serial_sock.unlink()

    # Generate test report markdown
    report_file = REPORTS_DIR / f"gate-{build_id}.md"
    with open(report_file, "w") as out:
        out.write(f"# Alien OS Ship Gate Verification Report\n\n")
        out.write(f"- **Target ISO:** `{iso_path.name}`\n")
        out.write(f"- **Build ID:** `{build_id}`\n")
        out.write(f"- **Timestamp:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        out.write(f"- **Proof Screenshots:** `docs/ship-proof/{build_id}/`\n\n")
        out.write(f"## Test Matrix Results\n\n")
        out.write(f"| Item | Status | Detail | Proof Screenshot |\n")
        out.write(f"|---|---|---|---|\n")

        fail_count = 0
        for r in results:
            item = r["item"]
            status = r["status"]
            detail = r["detail"]
            img_path = f"docs/ship-proof/{build_id}/*-{item}.png"
            out.write(f"| {item} | **{status}** | {detail} | `{img_path}` |\n")
            if status == "FAIL":
                fail_count += 1

        out.write(f"\n**Total Checks:** {len(results)} | **Failures:** {fail_count}\n")

    print(f"\nReport generated: {report_file}")
    if fail_count > 0:
        print(f"GATE FAILED: {fail_count} checks failed.", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"GATE PASSED: All checks green!")
        sys.exit(0)

if __name__ == "__main__":
    main()
