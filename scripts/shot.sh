#!/usr/bin/env bash
# scripts/shot.sh <name>
# Takes a screendump via the QEMU QMP socket and saves as PNG to docs/ship-proof/<BUILD_ID>/<name>.png.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:-}"

if [ -z "$NAME" ]; then
    echo "Usage: $0 <screenshot-name>" >&2
    exit 1
fi

# Determine BUILD_ID from running VM or newest ISO
VM_SOCK="$ROOT/vm/qmp.sock"
if [ ! -S "$VM_SOCK" ]; then
    echo "ERROR: QEMU QMP socket not found at $VM_SOCK. Is QEMU running?" >&2
    exit 1
fi

ISO=$(ls -t "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)
BUILD_ID="dev"
if [ -n "$ISO" ]; then
    ISO_BASENAME=$(basename "$ISO")
    if [[ "$ISO_BASENAME" =~ alien-[a-z]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)\.iso ]]; then
        BUILD_ID="${BASH_REMATCH[1]}"
    elif [[ "$ISO_BASENAME" =~ alien-[a-z]+-[0-9.]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)-amd64\.iso ]]; then
        BUILD_ID="${BASH_REMATCH[1]}"
    elif [[ "$ISO_BASENAME" =~ alien-[a-z]+-[0-9.]+-([a-f0-9]+-[0-9]{8}-[0-9]{4})-amd64\.iso ]]; then
        BUILD_ID="${BASH_REMATCH[1]}"
    fi
fi

OUT_DIR="$ROOT/docs/ship-proof/$BUILD_ID"
mkdir -p "$OUT_DIR"
DEST_PNG="$OUT_DIR/${NAME%.png}.png"
TMP_PPM="/tmp/qmp-shot-$$.ppm"

python3 - <<EOF
import socket, json, time, sys, os, subprocess

sock_path = "$VM_SOCK"
ppm_path = "$TMP_PPM"

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5.0)
s.connect(sock_path)
s.recv(1024)
s.sendall(b'{"execute": "qmp_capabilities"}\n')
s.recv(1024)

s.sendall(json.dumps({"execute": "screendump", "arguments": {"filename": ppm_path}}).encode() + b'\n')
s.recv(1024)
time.sleep(0.4)

if not os.path.exists(ppm_path):
    print("ERROR: screendump failed to write ppm file", file=sys.stderr)
    sys.exit(1)

# Convert to PNG
subprocess.run(["convert", ppm_path, "$DEST_PNG"], check=True)
if os.path.exists(ppm_path):
    os.remove(ppm_path)
EOF

echo "Screenshot saved: $DEST_PNG"
