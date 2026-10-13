#!/usr/bin/env python3
"""
tests/test-live-window.py — Test launching an app once prompt is confirmed and screendump
"""
import os, sys, time, socket, subprocess, shutil, json
from pathlib import Path

ROOT = Path("/home/nyakoe/Desktop/alien")
VM_DIR = ROOT / "vm"
ISO = ROOT / "out" / "alien-lite-20261013-1425-d43debb.iso"

serial_sock = VM_DIR / "live-serial.sock"
qmp_sock = VM_DIR / "live-qmp.sock"
vars_fd = VM_DIR / "live-vars.fd"

for f in [serial_sock, qmp_sock, vars_fd]:
    if f.exists(): f.unlink()

ovmf_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
ovmf_vars_orig = "/usr/share/OVMF/OVMF_VARS_4M.fd"
shutil.copyfile(ovmf_vars_orig, vars_fd)

cmd = [
    "qemu-system-x86_64", "-enable-kvm", "-machine", "q35", "-cpu", "host",
    "-smp", "2", "-m", "4096", "-vga", "virtio", "-display", "none",
    "-cdrom", str(ISO), "-boot", "d",
    "-drive", f"if=pflash,format=raw,readonly=on,file={ovmf_code}",
    "-drive", f"if=pflash,format=raw,file={vars_fd}",
    "-qmp", f"unix:{qmp_sock},server,nowait",
    "-serial", f"unix:{serial_sock},server,nowait",
    "-netdev", "user,id=net0", "-device", "virtio-net-pci,netdev=net0",
]
proc = subprocess.Popen(cmd)
time.sleep(2)

s_qmp = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s_qmp.connect(str(qmp_sock))
s_qmp.recv(1024)
s_qmp.sendall(b'{"execute": "qmp_capabilities"}\n')
s_qmp.recv(1024)

s_ser = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s_ser.connect(str(serial_sock))
s_ser.settimeout(1.0)

print("Waiting for root shell prompt '-bash-5.2#'...")
buf = ""
start = time.time()
while time.time() - start < 80:
    try:
        data = s_ser.recv(4096).decode("utf-8", errors="ignore")
        if data:
            buf += data
            if "-bash-5.2#" in buf:
                print("Root prompt ready!")
                break
    except socket.timeout:
        pass

time.sleep(3)
# Enable xhost for local users
s_ser.sendall(b"export DISPLAY=:0; export XAUTHORITY=/home/alien/.Xauthority; xhost + local:; xhost +\n")
time.sleep(2)

# Launch featherpad
s_ser.sendall(b"su - alien -c 'DISPLAY=:0 featherpad /etc/os-release' &\n")
time.sleep(4)

# Screendump
ppm = "/tmp/featherpad-test.ppm"
s_qmp.sendall(json.dumps({"execute": "screendump", "arguments": {"filename": ppm}}).encode("utf-8") + b"\n")
time.sleep(1)
if os.path.exists(ppm):
    subprocess.run(["convert", ppm, "/home/nyakoe/Desktop/alien/docs/ship-proof/20261013-1425-d43debb/featherpad-window.png"], check=True)
    os.remove(ppm)
    print("Featherpad screenshot saved!")

s_qmp.close()
s_ser.close()
proc.terminate()
try: proc.wait(5)
except: proc.kill()

for f in [serial_sock, qmp_sock, vars_fd]:
    if f.exists(): f.unlink()
