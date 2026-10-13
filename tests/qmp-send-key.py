#!/usr/bin/env python3
import sys, socket, json, time, os

if len(sys.argv) < 2:
    print("Usage: qmp-send-key.py <key1> [key2 ...]")
    sys.exit(1)

keys = sys.argv[1:]
sock_path = os.environ.get("QMP_SOCK", "/home/nyakoe/Desktop/alien/vm/qmp.sock")
if len(sys.argv) > 2 and sys.argv[1] == "--sock":
    sock_path = sys.argv[2]
    keys = sys.argv[3:]

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5.0)
s.connect(sock_path)

try:
    s.recv(4096)
    s.sendall(b'{"execute": "qmp_capabilities"}\n')
    s.recv(4096)

    qcodes = []
    for k in keys:
        qcodes.append({"type": "qcode", "data": k})

    cmd = json.dumps({"execute": "send-key", "arguments": {"keys": qcodes}}) + "\n"
    s.sendall(cmd.encode("utf-8"))
    s.recv(4096)
finally:
    s.close()

print(f"Sent keys: {keys}")
