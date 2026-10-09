#!/usr/bin/env bash
# Alien — test the ISO in a QEMU/KVM virtual machine (safe: never touches real disks).
#
#   ./scripts/test-in-qemu.sh            boot the ISO in UEFI mode (live session)
#   ./scripts/test-in-qemu.sh --bios     boot the ISO in old BIOS mode
#   ./scripts/test-in-qemu.sh --install  boot the ISO with an empty 40 GB virtual disk attached
#   ./scripts/test-in-qemu.sh --disk     boot the INSTALLED system from that virtual disk
#   ./scripts/test-in-qemu.sh --reset    delete the virtual disk and start over
# Add --bios to --install/--disk to test BIOS installs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM="$ROOT/vm"; mkdir -p "$VM"
ISO="$(ls -t "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)"
DISK="$VM/alien-disk.qcow2"

MODE=live; FW=uefi
for a in "$@"; do case "$a" in
  --bios) FW=bios ;; --install) MODE=install ;; --disk) MODE=disk ;;
  --reset) rm -f "$VM"/alien-disk.qcow2 "$VM"/OVMF_VARS*.fd; echo "VM reset."; exit 0 ;;
  *.iso) ISO="$a" ;;
  *) echo "Unknown option: $a"; exit 1 ;;
esac; done

ARGS=(-enable-kvm -machine q35 -cpu host -smp 2 -m 4096 -name "Alien test VM"
      -vga virtio -display gtk,zoom-to-fit=on
      -device qemu-xhci -device usb-tablet
      -nic user,model=virtio-net-pci
      -audiodev pa,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0
      -qmp unix:"$VM/qmp.sock",server,nowait)

if [ "$FW" = uefi ]; then
  CODE=/usr/share/OVMF/OVMF_CODE_4M.fd; VARS=/usr/share/OVMF/OVMF_VARS_4M.fd
  [ -f "$VM/OVMF_VARS_4M.fd" ] || cp "$VARS" "$VM/"
  ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE"
         -drive if=pflash,format=raw,file="$VM/OVMF_VARS_4M.fd")
fi

if [ "$MODE" != disk ]; then
  [ -n "$ISO" ] || { echo "No ISO in out/. Run ./build/build.sh first."; exit 1; }
  echo "Booting $ISO ($FW, $MODE)"
  ARGS+=(-cdrom "$ISO" -boot d)
fi
if [ "$MODE" != live ]; then
  [ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 40G
  ARGS+=(-drive file="$DISK",if=virtio,format=qcow2)
fi

exec qemu-system-x86_64 "${ARGS[@]}"
