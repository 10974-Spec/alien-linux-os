#!/usr/bin/env python3
import sys, socket, json, time

if len(sys.argv) < 2:
    print("Usage: qmp-type.py <text_or_key> ...")
    sys.exit(1)

sock_path = "/home/nyakoe/Desktop/alien/vm/qmp.sock"
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5.0)
s.connect(sock_path)

def send_qcode(code):
    cmd = json.dumps({"execute": "send-key", "arguments": {"keys": [{"type": "qcode", "data": code}]}}) + "\n"
    s.sendall(cmd.encode("utf-8"))
    s.recv(4096)
    time.sleep(0.04)

def send_combo(c1, c2):
    cmd = json.dumps({"execute": "send-key", "arguments": {"keys": [{"type": "qcode", "data": c1}, {"type": "qcode", "data": c2}]}}) + "\n"
    s.sendall(cmd.encode("utf-8"))
    s.recv(4096)
    time.sleep(0.04)

try:
    s.recv(4096)
    s.sendall(b'{"execute": "qmp_capabilities"}\n')
    s.recv(4096)

    for arg in sys.argv[1:]:
        if arg.startswith("key:"):
            send_qcode(arg[4:])
        else:
            for ch in arg:
                if ch == ' ':
                    send_qcode("spc")
                elif ch == '\n':
                    send_qcode("ret")
                elif ch == '-':
                    send_qcode("minus")
                elif ch == '_':
                    send_combo("shift", "minus")
                elif ch == '=':
                    send_qcode("equal")
                elif ch == '+':
                    send_combo("shift", "equal")
                elif ch == ';':
                    send_qcode("semicolon")
                elif ch == ':':
                    send_combo("shift", "semicolon")
                elif ch == '\'':
                    send_qcode("apostrophe")
                elif ch == '"':
                    send_combo("shift", "apostrophe")
                elif ch == '/':
                    send_qcode("slash")
                elif ch == '?':
                    send_combo("shift", "slash")
                elif ch == '.':
                    send_qcode("dot")
                elif ch == '>':
                    send_combo("shift", "dot")
                elif ch == ',':
                    send_qcode("comma")
                elif ch == '<':
                    send_combo("shift", "comma")
                elif ch == '(':
                    send_combo("shift", "9")
                elif ch == ')':
                    send_combo("shift", "0")
                elif ch == '{':
                    send_combo("shift", "bracket_left")
                elif ch == '}':
                    send_combo("shift", "bracket_right")
                elif ch == '[':
                    send_qcode("bracket_left")
                elif ch == ']':
                    send_qcode("bracket_right")
                elif ch == '&':
                    send_combo("shift", "7")
                elif ch == '|':
                    send_combo("shift", "backslash")
                elif ch.isupper():
                    send_combo("shift", ch.lower())
                elif ch.islower() or ch.isdigit():
                    send_qcode(ch)
                else:
                    send_qcode(ch)
finally:
    s.close()
