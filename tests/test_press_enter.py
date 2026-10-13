#!/usr/bin/env python3
import socket, json, time, os, subprocess, shutil

ROOT = "/home/nyakoe/Desktop/alien"
ISO = f"{ROOT}/out/alien-lite-0.1-20261011-amd64.iso"
sock_path = "/tmp/qmp-test-ret.sock"
vars_path = "/tmp/vars-ret.fd"
serial_path = "/tmp/serial-ret.log"

if os.path.exists(sock_path): os.remove(sock_path)
if os.path.exists(serial_path): os.remove(serial_path)
shutil.copyfile("/usr/share/OVMF/OVMF_VARS_4M.fd", vars_path)

cmd = [
    "qemu-system-x86_64",
    "-enable-kvm", "-machine", "q35", "-cpu", "host", "-smp", "2", "-m", "4096",
    "-vga", "virtio", "-display", "none",
    "-device", "qemu-xhci", "-device", "usb-tablet",
    "-nic", "user,model=virtio-net-pci",
    "-cdrom", ISO, "-boot", "d",
    "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd",
    "-drive", f"if=pflash,format=raw,file={vars_path}",
    "-qmp", f"unix:{sock_path},server,nowait",
    "-serial", f"file:{serial_path}"
]

proc = subprocess.Popen(cmd)

time.sleep(3.5)

# Connect to QMP
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock_path)
s.recv(4096)
s.sendall(b'{"execute": "qmp_capabilities"}\n')
s.recv(4096)

# Screendump 1: GRUB Menu
ppm1 = "/tmp/dump-menu.ppm"
s.sendall((json.dumps({"execute": "screendump", "arguments": {"filename": ppm1}}) + "\n").encode())
s.recv(4096)
time.sleep(0.5)
subprocess.run(["convert", ppm1, "/tmp/dump-menu.png"], check=True)

# Send Enter
s.sendall((json.dumps({"execute": "send-key", "arguments": {"keys": [{"type": "qcode", "data": "ret"}]}}) + "\n").encode())
s.recv(4096)
print("Sent RET to GRUB!")

# Wait 20 seconds
time.sleep(20.0)

# Screendump 2: After RET
ppm2 = "/tmp/dump-after.ppm"
s.sendall((json.dumps({"execute": "screendump", "arguments": {"filename": ppm2}}) + "\n").encode())
s.recv(4096)
s.close()
time.sleep(0.5)
subprocess.run(["convert", ppm2, "/tmp/dump-after.png"], check=True)

proc.terminate()
proc.wait()
print("Test complete.")
