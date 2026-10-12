#!/usr/bin/env bash
# scripts/run-latest.sh
# Finds the newest Alien ISO, prints its build ID and timestamp,
# warns loudly if older than latest commit,
# warns loudly if an existing installed disk image was built with a different build ID,
# and boots QEMU (KVM, 2 cores, 4 GB, UEFI by default, user-mode network).
#
# Flags:
#   --bios          Boot via legacy BIOS instead of UEFI
#   --disk <path>   Use specific disk image (defaults to vm/alien-disk.qcow2)
#   --fresh-disk    Wipe and create fresh 30 GB qcow2 test disk
#   --install       Attach disk alongside ISO for install testing

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM="$ROOT/vm"
mkdir -p "$VM"

ISO=""
FW="uefi"
MODE="live"
FRESH_DISK=0
CUSTOM_DISK=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bios) FW="bios"; shift ;;
        --uefi) FW="uefi"; shift ;;
        --fresh-disk) FRESH_DISK=1; shift ;;
        --install) MODE="install"; shift ;;
        --disk)
            if [[ $# -gt 1 && ! "$2" =~ ^-- ]]; then
                CUSTOM_DISK="$2"; MODE="disk"; shift 2
            else
                MODE="disk"; shift
            fi
            ;;
        *.iso) ISO="$1"; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$ISO" ]; then
    ISO=$(ls -t "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)
fi

if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
    echo "ERROR: No Alien ISO found in $ROOT/out/. Run './build/build.sh lite' first." >&2
    exit 1
fi

ISO_TIMESTAMP=$(date -r "$ISO" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)
ISO_MTIME=$(stat -c %Y "$ISO" 2>/dev/null || stat -f %m "$ISO" 2>/dev/null || echo 0)
ISO_BASENAME=$(basename "$ISO")

# Extract build ID from ISO filename or /etc/alien-build
BUILD_ID="unknown"
if [[ "$ISO_BASENAME" =~ alien-[a-z]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)\.iso ]]; then
    BUILD_ID="${BASH_REMATCH[1]}"
elif [[ "$ISO_BASENAME" =~ alien-[a-z]+-[0-9.]+-([0-9]{8}-[0-9]{4}-[a-f0-9]+)-amd64\.iso ]]; then
    BUILD_ID="${BASH_REMATCH[1]}"
elif [[ "$ISO_BASENAME" =~ alien-[a-z]+-[0-9.]+-([a-f0-9]+-[0-9]{8}-[0-9]{4})-amd64\.iso ]]; then
    BUILD_ID="${BASH_REMATCH[1]}"
fi

# Check if ISO is older than the latest git commit
GIT_COMMIT_TIME=$(git -C "$ROOT" log -1 --format=%ct 2>/dev/null || echo 0)
if [ "$GIT_COMMIT_TIME" -gt 0 ] && [ "$ISO_MTIME" -gt 0 ] && [ "$ISO_MTIME" -lt "$GIT_COMMIT_TIME" ]; then
    COMMIT_HASH=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "HEAD")
    echo
    echo "*******************************************************************************"
    echo " WARNING: ISO IS OLDER THAN LATEST GIT COMMIT!"
    echo " ISO timestamp:    $ISO_TIMESTAMP ($ISO_BASENAME)"
    echo " Latest commit:    $(git -C "$ROOT" log -1 --format='%cd (%h)' --date=format:'%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$COMMIT_HASH")"
    echo
    echo " You may be booting stale code! Rebuild the ISO with: ./build/build.sh lite"
    echo "*******************************************************************************"
    echo
    sleep 2
fi

DISK="${CUSTOM_DISK:-$VM/alien-disk.qcow2}"
DISK_STAMP="$VM/alien-disk.build-id"

if [ "$FRESH_DISK" -eq 1 ]; then
    echo ">>> --fresh-disk: Removing existing test disk and OVMF vars..."
    rm -f "$DISK" "$DISK_STAMP" "$VM/OVMF_VARS_user.fd"
    qemu-img create -f qcow2 "$DISK" 30G >/dev/null
    echo "$BUILD_ID" > "$DISK_STAMP"
    echo ">>> Clean 30G virtual disk created for build $BUILD_ID."
elif [ -f "$DISK" ]; then
    DISK_BUILD="unknown"
    [ -f "$DISK_STAMP" ] && DISK_BUILD=$(cat "$DISK_STAMP")
    if [ "$DISK_BUILD" != "$BUILD_ID" ]; then
        echo
        echo "*******************************************************************************"
        echo " WARNING: STALE INSTALLED DISK DETECTED!"
        echo " Installed disk: $DISK"
        echo " Disk was built from: Build '$DISK_BUILD'"
        echo " Newest ISO is:       Build '$BUILD_ID' ($ISO_TIMESTAMP)"
        echo
        echo " Booting from this disk will run the OLD system and will NOT contain any"
        echo " fixes or new applications from the latest build!"
        echo
        echo " To reset the disk image to the newest build, pass --fresh-disk:"
        echo "     $0 --fresh-disk"
        echo "*******************************************************************************"
        echo
        sleep 2
    fi
fi

echo "============================================================"
echo " Alien — Run Latest Build"
echo " ISO:       $ISO_BASENAME"
echo " Build ID:  $BUILD_ID"
echo " Timestamp: $ISO_TIMESTAMP"
echo " Firmware:  $FW"
echo " Mode:      $MODE"
echo " Disk:      ${DISK:-None}"
echo "============================================================"

ARGS=(
    -enable-kvm
    -machine q35
    -cpu host
    -smp 2
    -m 4096
    -name "Alien OS [Build: $BUILD_ID]"
    -vga virtio
    -display gtk,zoom-to-fit=on
    -device qemu-xhci
    -device usb-tablet
    -nic user,model=virtio-net-pci
    -audiodev pa,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0
    -qmp unix:"$VM/qmp.sock",server,nowait
)

if [ "$FW" = "uefi" ]; then
    CODE=""
    VARS=""
    for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/ovmf/OVMF.fd /usr/share/OVMF/OVMF_CODE.fd; do
        if [ -f "$c" ]; then CODE="$c"; break; fi
    done
    for v in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/ovmf/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS.fd; do
        if [ -f "$v" ]; then VARS="$v"; break; fi
    done
    
    if [ -n "$CODE" ] && [ -n "$VARS" ]; then
        [ -f "$VM/OVMF_VARS_user.fd" ] || cp "$VARS" "$VM/OVMF_VARS_user.fd"
        ARGS+=(
            -drive if=pflash,format=raw,readonly=on,file="$CODE"
            -drive if=pflash,format=raw,file="$VM/OVMF_VARS_user.fd"
        )
    else
        echo "Notice: OVMF not found, falling back to BIOS."
    fi
fi

if [ "$MODE" != "disk" ]; then
    ARGS+=(-cdrom "$ISO" -boot d)
fi

if [ "$MODE" = "install" ] || [ "$MODE" = "disk" ]; then
    [ -f "$DISK" ] || { qemu-img create -f qcow2 "$DISK" 30G >/dev/null; echo "$BUILD_ID" > "$DISK_STAMP"; }
    ARGS+=(-drive file="$DISK",if=virtio,format=qcow2)
fi

echo ">>> Launching QEMU..."
exec qemu-system-x86_64 "${ARGS[@]}"
