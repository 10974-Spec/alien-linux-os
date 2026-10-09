#!/usr/bin/env python3
import sys, socket, json, time

if len(sys.argv) < 3:
    print("Usage: qmp-click.py <pixel_x> <pixel_y> [width=1366] [height=672]")
    sys.exit(1)

px = float(sys.argv[1])
py = float(sys.argv[2])
width = float(sys.argv[3]) if len(sys.argv) > 3 else 1366.0
height = float(sys.argv[4]) if len(sys.argv) > 4 else 672.0

norm_x = int((px / width) * 32767)
norm_y = int((py / height) * 32767)

sock_path = "/home/nyakoe/Desktop/alien/vm/qmp.sock"
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5.0)
s.connect(sock_path)

try:
    s.recv(4096)
    s.sendall(b'{"execute": "qmp_capabilities"}\n')
    s.recv(4096)

    # Move cursor
    move_cmd = json.dumps({
        "execute": "input-send-event",
        "arguments": {
            "events": [
                {"type": "abs", "data": {"axis": "x", "value": norm_x}},
                {"type": "abs", "data": {"axis": "y", "value": norm_y}}
            ]
        }
    }) + "\n"
    s.sendall(move_cmd.encode("utf-8"))
    s.recv(4096)
    time.sleep(0.05)

    # Mouse down
    down_cmd = json.dumps({
        "execute": "input-send-event",
        "arguments": {
            "events": [
                {"type": "btn", "data": {"down": True, "button": "left"}}
            ]
        }
    }) + "\n"
    s.sendall(down_cmd.encode("utf-8"))
    s.recv(4096)
    time.sleep(0.05)

    # Mouse up
    up_cmd = json.dumps({
        "execute": "input-send-event",
        "arguments": {
            "events": [
                {"type": "btn", "data": {"down": False, "button": "left"}}
            ]
        }
    }) + "\n"
    s.sendall(up_cmd.encode("utf-8"))
    s.recv(4096)

finally:
    s.close()

print(f"Clicked at ({px}, {py}) -> ({norm_x}, {norm_y})")
