#!/usr/bin/env python3
"""
Alien OS Automated QEMU Boot Verification
Handles BIOS, UEFI, and UEFI Secure Boot verification with QMP screendumps,
menu navigation, and serial log capture.
"""
import os
import sys
import time
import socket
import json
import subprocess
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VM_DIR = os.path.join(ROOT, "vm")
REPORTS_DIR = os.path.join(ROOT, "docs", "test-reports")
ISO_PATH = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "out", "alien-lite-0.1-20261011-amd64.iso")

os.makedirs(VM_DIR, exist_ok=True)
os.makedirs(REPORTS_DIR, exist_ok=True)

class QmpClient:
    def __init__(self, sock_path):
        self.sock_path = sock_path
        self.sock = None

    def connect(self, timeout=30):
        start = time.time()
        while time.time() - start < timeout:
            if os.path.exists(self.sock_path):
                try:
                    self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.sock.settimeout(10.0)
                    self.sock.connect(self.sock_path)
                    # QMP greeting
                    self.sock.recv(4096)
                    self.sock.sendall(b'{"execute": "qmp_capabilities"}\n')
                    self.sock.recv(4096)
                    return True
                except Exception:
                    pass
            time.sleep(0.5)
        return False

    def send_cmd(self, execute, arguments=None):
        if not self.sock:
            return None
        payload = {"execute": execute}
        if arguments:
            payload["arguments"] = arguments
        cmd_str = json.dumps(payload) + "\n"
        self.sock.sendall(cmd_str.encode("utf-8"))
        res = b""
        while b"\n" not in res:
            chunk = self.sock.recv(4096)
            if not chunk:
                break
            res += chunk
        try:
            return json.loads(res.decode("utf-8"))
        except Exception:
            return None

    def screendump(self, out_png):
        ppm_path = f"/tmp/screendump-{os.getpid()}-{int(time.time()*1000)}.ppm"
        self.send_cmd("screendump", {"filename": ppm_path})
        time.sleep(0.4)
        if os.path.exists(ppm_path):
            os.makedirs(os.path.dirname(os.path.abspath(out_png)), exist_ok=True)
            subprocess.run(["convert", ppm_path, out_png], check=True)
            os.remove(ppm_path)
            print(f"  [+] Screendump saved: {out_png}")
            return True
        else:
            print(f"  [-] Screendump failed: {ppm_path} not found")
            return False

    def send_keys(self, key_list):
        qcodes = [{"type": "qcode", "data": k} for k in key_list]
        self.send_cmd("send-key", {"keys": qcodes})
        time.sleep(0.3)

    def close(self):
        if self.sock:
            try:
                self.sock.close()
            except Exception:
                pass
            self.sock = None

def run_boot_test(mode="uefi", sb=False, name="test"):
    print(f"\n=======================================================")
    print(f"Starting Boot Test: Mode={mode}, SecureBoot={sb}, Tag={name}")
    print(f"=======================================================")
    
    sock_path = os.path.join(VM_DIR, f"qmp-{name}.sock")
    serial_log = os.path.join(REPORTS_DIR, f"serial-{name}.log")
    vars_path = os.path.join(VM_DIR, f"vars-{name}.fd")

    if os.path.exists(sock_path):
        os.remove(sock_path)
    if os.path.exists(serial_log):
        os.remove(serial_log)

    cmd = [
        "qemu-system-x86_64",
        "-enable-kvm",
        "-machine", "q35",
        "-cpu", "host",
        "-smp", "2",
        "-m", "4096",
        "-name", f"Alien-Test-{name}",
        "-vga", "virtio",
        "-display", "none",
        "-device", "qemu-xhci",
        "-device", "usb-tablet",
        "-nic", "user,model=virtio-net-pci",
        "-cdrom", ISO_PATH,
        "-boot", "d",
        "-qmp", f"unix:{sock_path},server,nowait",
        "-serial", f"file:{serial_log}"
    ]

    if mode == "uefi":
        if sb:
            shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.ms.fd", vars_path)
            cmd.extend([
                "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd",
                "-drive", f"if=pflash,format=raw,file={vars_path}"
            ])
        else:
            shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.fd", vars_path)
            cmd.extend([
                "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd",
                "-drive", f"if=pflash,format=raw,file={vars_path}"
            ])

    proc = subprocess.Popen(cmd)
    qmp = QmpClient(sock_path)

    try:
        if not qmp.connect(timeout=25):
            print("  [-] Failed to connect to QMP socket!")
            proc.kill()
            return False

        print("  [+] QMP connected. Pausing / capturing GRUB menu...")
        # Give GRUB 4.5 seconds to load graphics and render theme
        time.sleep(4.5 if mode == "bios" else 5.0)
        
        # Capture GRUB main menu
        qmp.screendump(os.path.join(REPORTS_DIR, f"grub-menu-{name}.png"))

        # Navigate down to "Tools & Diagnostics"
        for _ in range(5):
            qmp.send_keys(["down"])
            time.sleep(0.3)
        
        # Enter submenu
        qmp.send_keys(["ret"])
        time.sleep(1.5)
        qmp.screendump(os.path.join(REPORTS_DIR, f"grub-submenu-tools-{name}.png"))

        # Return to main menu
        qmp.send_keys(["esc"])
        time.sleep(1.0)

        # Go back to top entry (Alien Lite Live)
        for _ in range(5):
            qmp.send_keys(["up"])
            time.sleep(0.2)
        
        # Boot Live system
        print("  [+] Booting live system...")
        qmp.send_keys(["ret"])

        # Wait for desktop to boot and settle
        boot_start = time.time()
        desktop_reached = False
        print("  [+] Waiting 35s for system boot to reach graphical desktop...")
        time.sleep(35.0)

        # Allow graphical session to settle
        desktop_png = os.path.join(REPORTS_DIR, f"live-desktop-{name}.png")
        qmp.screendump(desktop_png)
        if os.path.exists(desktop_png) and os.path.getsize(desktop_png) > 100000:
            desktop_reached = True
            print(f"  [+] Milestone reached: desktop captured successfully ({os.path.getsize(desktop_png)} bytes)")
        else:
            print(f"  [-] Desktop capture size too small or missing!")

        print(f"  [+] Test {name} completed: desktop_reached={desktop_reached}")
        return desktop_reached

    finally:
        qmp.close()
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()

if __name__ == "__main__":
    test_type = sys.argv[2] if len(sys.argv) > 2 else "all"
    results = {}
    
    if test_type in ("all", "bios"):
        results["bios"] = run_boot_test(mode="bios", sb=False, name="bios")
    if test_type in ("all", "uefi"):
        results["uefi"] = run_boot_test(mode="uefi", sb=False, name="uefi")
    if test_type in ("all", "secboot"):
        results["uefi-secboot"] = run_boot_test(mode="uefi", sb=True, name="uefi-secboot")
    
    print("\n================ Boot Test Results ================")
    for k, v in results.items():
        print(f"  {k}: {'PASS' if v else 'FAIL'}")
