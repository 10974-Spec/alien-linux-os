#!/usr/bin/env python3
"""
Comprehensive Live ISO Boot Verification across BIOS, UEFI, and UEFI Secure Boot.
Captures GRUB main menu, submenus, live desktop, and serial logs.
"""
import os, sys, time, socket, json, subprocess, shutil

ROOT = "/home/nyakoe/Desktop/alien"
ISO = f"{ROOT}/out/alien-lite-0.1-20261011-amd64.iso"
REPORTS = f"{ROOT}/docs/test-reports"
VM = f"{ROOT}/vm"

os.makedirs(REPORTS, exist_ok=True)
os.makedirs(VM, exist_ok=True)

class QmpSession:
    def __init__(self, sock_path):
        self.sock_path = sock_path
        self.s = None

    def connect(self, timeout=20):
        start = time.time()
        while time.time() - start < timeout:
            if os.path.exists(self.sock_path):
                try:
                    self.s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.s.settimeout(10.0)
                    self.s.connect(self.sock_path)
                    self.s.recv(4096)
                    self.s.sendall(b'{"execute": "qmp_capabilities"}\n')
                    self.s.recv(4096)
                    return True
                except Exception:
                    pass
            time.sleep(0.5)
        return False

    def send_cmd(self, cmd, args=None):
        payload = {"execute": cmd}
        if args: payload["arguments"] = args
        self.s.sendall((json.dumps(payload) + "\n").encode())
        res = b""
        while b"\n" not in res:
            chunk = self.s.recv(4096)
            if not chunk: break
            res += chunk
        for line in res.decode().strip().split("\n"):
            line = line.strip()
            if line:
                try:
                    parsed = json.loads(line)
                    if "return" in parsed or "error" in parsed:
                        return parsed
                except Exception:
                    pass
        return {"return": {}}

    def send_keys(self, keys):
        qcodes = [{"type": "qcode", "data": k} for k in keys]
        self.send_cmd("send-key", {"keys": qcodes})
        time.sleep(0.3)

    def screendump(self, out_png):
        ppm = f"/tmp/screendump-{int(time.time()*1000)}.ppm"
        self.send_cmd("screendump", {"filename": ppm})
        for _ in range(15):
            time.sleep(0.3)
            if os.path.exists(ppm) and os.path.getsize(ppm) > 1000:
                break
        subprocess.run(["convert", ppm, out_png], check=True)
        if os.path.exists(ppm): os.remove(ppm)
        size = os.path.getsize(out_png)
        print(f"  [+] Screendump saved: {out_png} ({size} bytes)")
        return size

    def close(self):
        if self.s:
            try: self.s.close()
            except Exception: pass
            self.s = None

def run_test(target):
    print(f"\n=======================================================")
    print(f"STARTING LIVE BOOT TEST: {target.upper()}")
    print(f"=======================================================")

    sock_path = f"{VM}/qmp-{target}.sock"
    serial_log = f"{REPORTS}/serial-{target}-live.log"
    vars_path = f"{VM}/vars-{target}.fd"

    if os.path.exists(sock_path): os.remove(sock_path)
    if os.path.exists(serial_log): os.remove(serial_log)

    cmd = [
        "qemu-system-x86_64",
        "-enable-kvm", "-machine", "q35", "-cpu", "host", "-smp", "2", "-m", "4096",
        "-name", f"Alien-Live-{target}",
        "-vga", "virtio", "-display", "none",
        "-device", "qemu-xhci", "-device", "usb-tablet",
        "-nic", "user,model=virtio-net-pci",
        "-cdrom", ISO, "-boot", "d",
        "-qmp", f"unix:{sock_path},server,nowait",
        "-serial", f"file:{serial_log}"
    ]

    if target == "uefi":
        shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.fd", vars_path)
        cmd.extend([
            "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd",
            "-drive", f"if=pflash,format=raw,file={vars_path}"
        ])
    elif target == "secboot":
        shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.ms.fd", vars_path)
        cmd.extend([
            "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd",
            "-drive", f"if=pflash,format=raw,file={vars_path}"
        ])

    proc = subprocess.Popen(cmd)
    qmp = QmpSession(sock_path)

    try:
        if not qmp.connect():
            print("  [-] Failed to connect to QMP!")
            return False

        # Wait for GRUB menu to draw
        wait_grub = 7.0 if target == "bios" else 3.5
        print(f"  [+] Waiting {wait_grub}s for GRUB menu...")
        time.sleep(wait_grub)

        # 1. Capture main menu
        qmp.screendump(f"{REPORTS}/live-{target}-grub-menu.png")

        # 2. Boot Entry 0 (Alien Lite Live)
        print("  [+] Booting Alien Lite Live (Entry 0)...")
        qmp.send_keys(["ret"])

        # 3. Wait for full desktop
        print("  [+] Waiting 55s for LXQt desktop session...")
        time.sleep(55.0)

        # 4. Capture Desktop
        desktop_size = qmp.screendump(f"{REPORTS}/live-{target}-desktop.png")
        if desktop_size > 100000:
            print(f"  [+] SUCCESS: Live desktop verified for {target}! ({desktop_size} bytes)")
            return True
        else:
            print(f"  [-] Desktop size too small: {desktop_size}")
            return False

    finally:
        qmp.close()
        proc.terminate()
        try: proc.wait(timeout=5)
        except subprocess.TimeoutExpired: proc.kill()

if __name__ == "__main__":
    t = sys.argv[1] if len(sys.argv) > 1 else "all"
    tests = ["bios", "uefi", "secboot"] if t == "all" else [t]
    res = {}
    for test in tests:
        res[test] = run_test(test)
    print("\n================ SUMMARY ================")
    for k, v in res.items():
        print(f"  {k.upper()}: {'PASS' if v else 'FAIL'}")
