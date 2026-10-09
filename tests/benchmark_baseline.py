#!/usr/bin/env python3
import os
import sys
import time
import json
import socket
import subprocess

ROOT = "/home/nyakoe/Desktop/alien"
VM_DIR = os.path.join(ROOT, "vm")
SOCK_PATH = os.path.join(VM_DIR, "qmp.sock")
ISO_PATH = os.path.join(ROOT, "out", "alien-lite-0.1-20261008-amd64.iso")
OUT_DIR = os.path.join(ROOT, "docs", "branding-screenshots")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(VM_DIR, exist_ok=True)

if os.path.exists(SOCK_PATH):
    try:
        os.remove(SOCK_PATH)
    except Exception:
        pass

ovmf_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
vm_vars = os.path.join(VM_DIR, "OVMF_VARS_4M.fd")

qemu_cmd = [
    "qemu-system-x86_64",
    "-enable-kvm",
    "-machine", "q35",
    "-cpu", "host",
    "-smp", "2",
    "-m", "4096",
    "-name", "Alien-Baseline-Test",
    "-vga", "virtio",
    "-display", "none",
    "-vnc", ":10",
    "-device", "qemu-xhci",
    "-device", "usb-tablet",
    "-nic", "user,model=virtio-net-pci",
    "-qmp", f"unix:{SOCK_PATH},server,nowait",
    "-drive", f"if=pflash,format=raw,readonly=on,file={ovmf_code}",
    "-drive", f"if=pflash,format=raw,file={vm_vars}",
    "-cdrom", ISO_PATH,
    "-boot", "d"
]

print(f"Starting QEMU baseline test on {ISO_PATH}...")
start_time = time.time()
proc = subprocess.Popen(qemu_cmd)

def send_qmp(cmd_obj):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5.0)
    s.connect(SOCK_PATH)
    try:
        s.recv(4096)
        s.sendall(b'{"execute": "qmp_capabilities"}\n')
        s.recv(4096)
        s.sendall((json.dumps(cmd_obj) + "\n").encode("utf-8"))
        res = s.recv(4096)
        return res
    finally:
        s.close()

# Wait for socket
connected = False
for _ in range(30):
    if os.path.exists(SOCK_PATH):
        try:
            test_s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            test_s.connect(SOCK_PATH)
            test_s.close()
            connected = True
            break
        except Exception:
            pass
    time.sleep(0.5)

if not connected:
    print("Could not connect to QMP socket!")
    proc.terminate()
    sys.exit(1)

print("QMP connected. Monitoring boot...")
ppm_path = "/tmp/baseline-screen.ppm"
png_path = os.path.join(OUT_DIR, "baseline_lite_desktop.png")

kernel_booted = False
desktop_reached = False
boot_duration = 0
enter_sent = False

for i in range(75):
    time.sleep(1.0)
    elapsed = time.time() - start_time
    try:
        send_qmp({"execute": "screendump", "arguments": {"filename": ppm_path}})
        if os.path.exists(ppm_path) and os.path.getsize(ppm_path) > 100000:
            subprocess.run(["convert", ppm_path, png_path], check=True)
            info = subprocess.check_output(["identify", "-format", "%w %h %[colors]", png_path]).decode().strip()
            parts = info.split()
            w, h = int(parts[0]), int(parts[1])
            num_colors = int(parts[2]) if len(parts) >= 3 else 0

            # GRUB menu detected -> send Enter
            if not enter_sent and num_colors > 400000 and w == 800 and h == 600:
                print(f"t={elapsed:.1f}s: GRUB menu detected! Sending Enter...")
                send_qmp({"execute": "send-key", "arguments": {"keys": [{"type": "qcode", "data": "ret"}]}})
                enter_sent = True
                continue

            if enter_sent and not kernel_booted and elapsed > 15:
                kernel_booted = True
                print(f"t={elapsed:.1f}s: Kernel running...")

            # When desktop is reached, the alien wallpaper (light blue with clouds/alien) has thousands of colors (>10000) and resolution is not GRUB 800x600 (or w>800 with >10000 colors)
            if kernel_booted and elapsed > 25 and num_colors > 10000:
                print(f"t={elapsed:.1f}s: DESKTOP REACHED! {w}x{h} with {num_colors} colors")
                desktop_reached = True
                boot_duration = elapsed
                break
            else:
                if i % 5 == 0:
                    print(f"t={elapsed:.1f}s: {w}x{h} ({num_colors} colors)")
    except Exception as e:
        print(f"Polling error at {elapsed:.1f}s: {e}")

if desktop_reached:
    time.sleep(4)
    send_qmp({"execute": "screendump", "arguments": {"filename": ppm_path}})
    if os.path.exists(ppm_path):
        subprocess.run(["convert", ppm_path, png_path], check=True)

print(f"Measured baseline boot time: {boot_duration:.1f}s, Desktop reached: {desktop_reached}")

try:
    send_qmp({"execute": "quit"})
except Exception:
    proc.terminate()
proc.wait(timeout=5)
print("QEMU stopped successfully.")
