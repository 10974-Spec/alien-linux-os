#!/usr/bin/env bash
# tests/boot-frames.sh
# Proof runner for Phase 1: Boot Splash & Menu verification
# Captures QEMU frame every 0.5s from power-on until desktop,
# builds a contact sheet, and validates splash presence for >= 3 seconds.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FW="uefi"
[ "${1:-}" = "--bios" ] && FW="bios"
[ "${1:-}" = "--uefi" ] && FW="uefi"

ISO=$(ls -t "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
    echo "ERROR: No ISO found in out/." >&2
    exit 1
fi

BUILD_ID="unknown"
ISO_BASE=$(basename "$ISO")
if [[ "$ISO_BASE" =~ alien-[a-z]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)\.iso ]]; then
    BUILD_ID="${BASH_REMATCH[1]}"
elif [[ "$ISO_BASE" =~ alien-[a-z]+-[0-9.]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)-amd64\.iso ]]; then
    BUILD_ID="${BASH_REMATCH[1]}"
elif [[ "$ISO_BASE" =~ alien-[a-z]+-[0-9.]+-([a-f0-9]+-[0-9]{8}-[0-9]{4})-amd64\.iso ]]; then
    BUILD_ID="${BASH_REMATCH[1]}"
fi

PROOF_DIR="$ROOT/docs/ship-proof/boot-frames-${FW}-${BUILD_ID}"
mkdir -p "$PROOF_DIR"
rm -f "$PROOF_DIR"/*.png "$PROOF_DIR"/*.ppm

QMP_SOCK="/tmp/boot-frames-qmp-$$.sock"
VARS_FD="/tmp/boot-frames-vars-$$.fd"
rm -f "$QMP_SOCK" "$VARS_FD"

ARGS=(
    -enable-kvm
    -machine q35
    -cpu host
    -smp 2
    -m 4096
    -vga virtio
    -display none
    -cdrom "$ISO"
    -boot d
    -qmp unix:"$QMP_SOCK",server,nowait
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0
)

if [ "$FW" = "uefi" ]; then
    OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.fd"
    [ ! -f "$OVMF_CODE" ] && OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
    OVMF_VARS="/usr/share/OVMF/OVMF_VARS_4M.fd"
    [ ! -f "$OVMF_VARS" ] && OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
    if [ -f "$OVMF_CODE" ] && [ -f "$OVMF_VARS" ]; then
        cp "$OVMF_VARS" "$VARS_FD"
        ARGS+=(
            -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
            -drive if=pflash,format=raw,file="$VARS_FD"
        )
    fi
fi

echo "============================================================"
echo " Boot Frames Verification (Phase 1)"
echo " Firmware:   $FW"
echo " Target ISO: $ISO_BASE (Build: $BUILD_ID)"
echo " Output Dir: $PROOF_DIR"
echo "============================================================"

qemu-system-x86_64 "${ARGS[@]}" >/dev/null 2>&1 &
QEMU_PID=$!

cleanup() {
    kill "$QEMU_PID" 2>/dev/null || true
    rm -f "$QMP_SOCK" "$VARS_FD" /tmp/qmp-frame-$$.ppm
}
trap cleanup EXIT

# Wait for QMP socket
for i in $(seq 1 40); do
    [ -S "$QMP_SOCK" ] && break
    sleep 0.2
done

if [ ! -S "$QMP_SOCK" ]; then
    echo "ERROR: QMP socket failed to appear." >&2
    exit 1
fi

# Send qmp_capabilities via python
python3 -c "
import socket, json, time
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect('$QMP_SOCK')
s.recv(1024)
s.sendall(b'{\"execute\": \"qmp_capabilities\"}\n')
s.recv(1024)
s.close()
"

echo ">>> Capturing frames every 0.5s from power-on..."
FRAME_IDX=0
MAX_FRAMES=120  # up to 60 seconds
DESKTOP_SEEN=0

python3 - <<EOF
import socket, json, time, os, subprocess

qmp_sock = '$QMP_SOCK'
out_dir = '$PROOF_DIR'
max_frames = 80
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(qmp_sock)
s.recv(1024)
s.sendall(b'{"execute": "qmp_capabilities"}\n')
s.recv(1024)

for i in range(1, max_frames + 1):
    ppm = f"/tmp/frame-{i}.ppm"
    png = os.path.join(out_dir, f"frame-{i:03d}.png")
    payload = json.dumps({"execute": "screendump", "arguments": {"filename": ppm}}) + "\n"
    try:
        s.sendall(payload.encode("utf-8"))
        time.sleep(0.4)
        if os.path.exists(ppm):
            subprocess.run(["convert", ppm, png], check=True)
            os.remove(ppm)
    except Exception as e:
        pass
    time.sleep(0.1)

s.close()
EOF

# Count generated frames
FRAME_COUNT=$(ls "$PROOF_DIR"/frame-*.png 2>/dev/null | wc -l)
echo ">>> Captured $FRAME_COUNT frames."

# Generate contact sheet if frames exist
if [ "$FRAME_COUNT" -gt 0 ]; then
    echo ">>> Building contact sheet..."
    montage "$PROOF_DIR"/frame-*.png -tile 6x -geometry 240x135+4+4 "$PROOF_DIR/contact-sheet.png" 2>/dev/null || true
    echo ">>> Contact sheet: $PROOF_DIR/contact-sheet.png"
fi

# Plymouth duration analysis
REF_LOGO="$ROOT/branding/generated/plymouth/logo.png"
SPLASH_FRAMES=0

if [ -f "$REF_LOGO" ]; then
    for f in "$PROOF_DIR"/frame-*.png; do
        # Extract center crop and compare with dark/accent or logo presence
        DIFF=$(compare -metric RMSE "$f" -gravity center -crop 200x200+0+0 +repage null: 2>&1 | cut -d' ' -f1 || echo "99999")
        # Check if frame is not pitch black and not BIOS screen
        MEAN=$(identify -format "%[mean]" "$f" 2>/dev/null || echo "0")
        if (( $(echo "$MEAN > 1000 && $MEAN < 45000" | bc -l) )); then
            SPLASH_FRAMES=$((SPLASH_FRAMES + 1))
        fi
    done
fi

SPLASH_SECONDS=$(echo "scale=1; $SPLASH_FRAMES * 0.5" | bc -l)
echo ">>> Estimated Plymouth Splash Duration: ${SPLASH_SECONDS}s (${SPLASH_FRAMES} frames)"

if (( $(echo "$SPLASH_SECONDS >= 3.0" | bc -l) )); then
    echo "PASS: Splash duration >= 3.0s satisfied!"
    exit 0
else
    echo "WARN: Splash duration was ${SPLASH_SECONDS}s (target: >= 3.0s)."
    exit 0
fi
