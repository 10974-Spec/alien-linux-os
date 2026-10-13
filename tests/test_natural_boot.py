#!/usr/bin/env python3
import os, sys, time, socket, json, subprocess, shutil

ROOT = "/home/nyakoe/Desktop/alien"
ISO = "/home/nyakoe/Desktop/alien/out/alien-lite-0.1-20261011-amd64.iso"
REPORTS = "/home/nyakoe/Desktop/alien/docs/test-reports"
VM = "/home/nyakoe/Desktop/alien/vm"

mode = sys.argv[1] if len(sys.argv) > 1 else "uefi" # bios, uefi, secboot

sock_path = f"{VM}/qmp-{mode}.sock"
serial_log = f"{REPORTS}/serial-{mode}.log"
vars_path = f"{VM}/vars-{mode}.fd"

if os.path.exists(sock_path): os.remove(sock_path)
if os.path.exists(serial_log): os.remove(serial_log)

cmd = [
    "qemu-system-x86_64",
    "-enable-kvm", "-machine", "q35", "-cpu", "host", "-smp", "2", "-m", "4096",
    "-name", f"Alien-Natural-{mode}",
    "-vga", "virtio", "-display", "none",
    "-device", "qemu-xhci", "-device", "usb-tablet",
    "-nic", "user,model=virtio-net-pci",
    "-cdrom", ISO, "-boot", "d",
    "-qmp", f"unix:{sock_path},server,nowait",
    "-serial", f"file:{serial_log}"
]

if mode == "uefi":
    shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.fd", vars_path)
    cmd.extend([
        "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd",
        "-drive", f"if=pflash,format=raw,file={vars_path}"
    ])
elif mode == "secboot":
    shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.ms.fd", vars_path)
    cmd.extend([
        "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd",
        "-drive", f"if=pflash,format=raw,file={vars_path}"
    ])

proc = subprocess.Popen(cmd)

def qmp_cmd(cmd_name, args=None):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5.0)
    s.connect(sock_path)
    s.recv(4096)
    s.sendall(b'{"execute": "qmp_capabilities"}\n')
    s.recv(4096)
    payload = {"execute": cmd_name}
    if args: payload["arguments"] = args
    s.sendall((json.dumps(payload) + "\n").encode())
    res = s.recv(4096)
    s.close()
    return res

def screendump(out_path):
    ppm = f"/tmp/dump-{int(time.time()*1000)}.ppm"
    qmp_cmd("screendump", {"filename": ppm})
    time.sleep(0.5)
    if os.path.exists(ppm):
        subprocess.run(["convert", ppm, out_path], check=True)
        os.remove(ppm)
        print(f"Captured: {out_path} ({os.path.getsize(out_path)} bytes)")
        return True
    return False

# Wait for QMP
for _ in range(30):
    if os.path.exists(sock_path): break
    time.sleep(0.5)

print("Connected to QMP. Waiting 3.5s for GRUB...")
time.sleep(3.5 if mode != "bios" else 7.0)

# 1. Capture GRUB menu
screendump(f"{REPORTS}/live-{mode}-grub-menu.png")

# 2. Wait for auto boot (timeout 5s + boot time 40s)
print("Waiting 45s for live system boot...")
time.sleep(45.0)

# 3. Capture desktop
screendump(f"{REPORTS}/live-{mode}-desktop.png")

# Terminate VM
proc.terminate()
try:
    proc.wait(timeout=5)
except subprocess.TimeoutExpired:
    proc.kill()

print(f"Done testing mode: {mode}")
