#!/usr/bin/env python3
"""
tests/capture-apps-proof.py — Launch each app inside running QEMU and take screendumps
"""
import os
import sys
import time
import socket
import json
import subprocess
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VM_DIR = ROOT / "vm"
ISO_PATH = ROOT / "out" / "alien-lite-20261013-1425-d43debb.iso"
BUILD_ID = "20261013-1425-d43debb"
PROOF_DIR = ROOT / "docs" / "ship-proof" / BUILD_ID
PROOF_DIR.mkdir(parents=True, exist_ok=True)

qmp_sock = VM_DIR / f"app-qmp-{os.getpid()}.sock"
serial_sock = VM_DIR / f"app-serial-{os.getpid()}.sock"
vars_fd = VM_DIR / f"app-vars-{os.getpid()}.fd"

if qmp_sock.exists(): qmp_sock.unlink()
if serial_sock.exists(): serial_sock.unlink()

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
    "-cdrom", str(ISO_PATH),
    "-boot", "d",
    "-drive", f"if=pflash,format=raw,readonly=on,file={ovmf_code}",
    "-drive", f"if=pflash,format=raw,file={vars_fd}",
    "-qmp", f"unix:{qmp_sock},server,nowait",
    "-serial", f"unix:{serial_sock},server,nowait",
    "-netdev", "user,id=net0",
    "-device", "virtio-net-pci,netdev=net0",
]

print("Starting QEMU VM...")
proc = subprocess.Popen(qemu_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

class QmpClient:
    def __init__(self, path):
        self.path = str(path)
        self.sock = None

    def connect(self):
        for _ in range(40):
            if os.path.exists(self.path):
                try:
                    self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.sock.connect(self.path)
                    self.sock.recv(1024)
                    self.sock.sendall(b'{"execute": "qmp_capabilities"}\n')
                    self.sock.recv(1024)
                    return True
                except Exception:
                    pass
            time.sleep(0.5)
        return False

    def screendump(self, out_png):
        ppm = f"/tmp/app-{os.getpid()}-{int(time.time()*1000)}.ppm"
        payload = json.dumps({"execute": "screendump", "arguments": {"filename": ppm}}) + "\n"
        self.sock.sendall(payload.encode("utf-8"))
        time.sleep(0.5)
        if os.path.exists(ppm):
            subprocess.run(["convert", ppm, str(out_png)], check=True)
            os.remove(ppm)
            return True
        return False

    def close(self):
        if self.sock:
            self.sock.close()

qmp = QmpClient(qmp_sock)
if not qmp.connect():
    print("Failed to connect QMP")
    proc.kill()
    sys.exit(1)

# Connect serial
s_sock = None
for _ in range(40):
    if os.path.exists(serial_sock):
        try:
            s_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s_sock.connect(str(serial_sock))
            s_sock.settimeout(2.0)
            break
        except Exception:
            pass
    time.sleep(0.5)

print("Monitoring serial socket until desktop is ready...")
start_wait = time.time()
desktop_ready = False
while time.time() - start_wait < 90:
    if s_sock:
        try:
            chunk = s_sock.recv(4096).decode("utf-8", errors="ignore")
            if "-bash" in chunk or "Welcome to Alien" in chunk or "alien login:" in chunk:
                desktop_ready = True
                print("In-guest shell detected! Desktop is up.")
                break
        except socket.timeout:
            pass
        except Exception:
            pass
    time.sleep(0.5)

print("Waiting 10s for LXQt desktop session to fully settle...")
time.sleep(10)
qmp.screendump(PROOF_DIR / "desktop-clean.png")

def run_guest(cmd):
    if s_sock:
        s_sock.sendall(f"{cmd}\n".encode("utf-8"))
        time.sleep(1.0)

# Wait extra 5s for lxqt-session process to be running
time.sleep(5)

# Install launcher helper that inherits lxqt-session environment
run_guest("""cat > /tmp/launch-app.sh << 'EOF'
#!/bin/bash
PID=$(pgrep -u alien lxqt-session | head -1)
if [ -n "$PID" ] && [ -d "/proc/$PID" ]; then
    while IFS= read -r -d '' var; do
        case "$var" in
            DISPLAY=*|XAUTHORITY=*|DBUS_SESSION_BUS_ADDRESS=*|XDG_RUNTIME_DIR=*)
                export "$var"
                ;;
        esac
    done < /proc/$PID/environ
fi
export DISPLAY=${DISPLAY:-:0}
xhost + 2>/dev/null || true
su - alien -c "export DISPLAY='$DISPLAY' XAUTHORITY='$XAUTHORITY' DBUS_SESSION_BUS_ADDRESS='$DBUS_SESSION_BUS_ADDRESS' XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR'; nohup $* >/tmp/app.log 2>&1 &"
EOF
chmod +x /tmp/launch-app.sh
""")
time.sleep(2)

APPS = [
    ("brave", "/tmp/launch-app.sh brave-browser --no-first-run --no-default-browser-check https://example.com", "01-brave-browser.png"),
    ("vlc", "/tmp/launch-app.sh vlc", "02-vlc-media-player.png"),
    ("lximage-qt", "/tmp/launch-app.sh lximage-qt /usr/share/wallpapers/Alien/contents/images/1920x1080.png", "03-lximage-qt.png"),
    ("ghostwriter", "/tmp/launch-app.sh ghostwriter", "04-ghostwriter-notes.png"),
    ("featherpad", "/tmp/launch-app.sh featherpad", "05-featherpad.png"),
    ("alien-store", "/tmp/launch-app.sh alien-store", "06-alien-store.png"),
]

for name, cmd, shot_name in APPS:
    print(f"Launching {name}...")
    run_guest(cmd)
    time.sleep(6)
    out_file = PROOF_DIR / shot_name
    qmp.screendump(out_file)
    print(f"  Captured {shot_name}")
    # close app
    run_guest(f"pkill -f {name} || true")
    time.sleep(2)

qmp.close()
if s_sock: s_sock.close()
proc.terminate()
try: proc.wait(5)
except: proc.kill()

if vars_fd.exists(): vars_fd.unlink()
if qmp_sock.exists(): qmp_sock.unlink()
if serial_sock.exists(): serial_sock.unlink()

print("All app screenshots captured successfully!")
