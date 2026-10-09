#!/usr/bin/env python3
import sys, socket, json, time, os, subprocess

if len(sys.argv) < 2:
    print("Usage: capture-screenshot.py <output.png>")
    sys.exit(1)

out_png = sys.argv[1]
sock_path = "/home/nyakoe/Desktop/alien/vm/qmp.sock"
ppm_path = "/tmp/qemu-screenshot.ppm"

if not os.path.exists(sock_path):
    print(f"Error: QMP socket {sock_path} not found.")
    sys.exit(1)

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5.0)
s.connect(sock_path)

try:
    # Read QMP greeting
    data = s.recv(4096)
    s.sendall(b'{"execute": "qmp_capabilities"}\n')
    data = s.recv(4096)

    # Screendump
    cmd = json.dumps({"execute": "screendump", "arguments": {"filename": ppm_path}}) + "\n"
    s.sendall(cmd.encode("utf-8"))
    data = s.recv(4096)
finally:
    s.close()

time.sleep(0.5)

if not os.path.exists(ppm_path):
    print("Error: screendump failed to generate PPM.")
    sys.exit(1)

os.makedirs(os.path.dirname(os.path.abspath(out_png)), exist_ok=True)
subprocess.run(["convert", ppm_path, out_png], check=True)
if os.path.exists(ppm_path):
    os.remove(ppm_path)

print(f"Captured screenshot to: {out_png}")
