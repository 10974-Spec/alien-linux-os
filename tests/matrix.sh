#!/usr/bin/env bash
# Alien OS — Compatibility Matrix & Verification Test Runner
# Tests configurations across BIOS, UEFI, UEFI Secure Boot, RAM tiers, and media.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM="$ROOT/vm"
REPORTS="$ROOT/docs/test-reports"
mkdir -p "$VM" "$REPORTS"

ISO="${ISO:-$(ls -t "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)}"
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
  echo "Error: No ISO found in out/. Build an ISO first." >&2
  exit 1
fi
echo "Using ISO: $ISO"

run_config() {
  local cfg_id="$1"
  local fw="$2"
  local sb="$3"
  local ram="$4"
  local disk_type="$5"
  local toram="$6"
  local persist="$7"

  echo "=== Running Config $cfg_id: FW=$fw, SB=$sb, RAM=${ram}MB, Disk=$disk_type, toram=$toram, persist=$persist ==="

  local qmp_sock="$VM/qmp-$cfg_id.sock"
  local serial_log="$REPORTS/serial-cfg-$cfg_id.log"
  local screenshot="$REPORTS/screenshot-cfg-$cfg_id.png"
  local ovmf_vars="$VM/vars-cfg-$cfg_id.fd"
  rm -f "$qmp_sock" "$serial_log"

  local qemu_args=(
    -enable-kvm -machine q35 -cpu host -smp 2 -m "$ram"
    -name "Alien Test Config $cfg_id"
    -vga virtio -display none
    -device qemu-xhci -device usb-tablet
    -nic user,model=virtio-net-pci
    -audiodev none,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0
    -qmp "unix:$qmp_sock,server,nowait"
    -serial "file:$serial_log"
  )

  # Firmware selection
  if [ "$fw" = "uefi" ]; then
    if [ "$sb" = "On" ]; then
      cp -f /usr/share/OVMF/OVMF_VARS_4M.ms.fd "$ovmf_vars"
      qemu_args+=(
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd
        -drive if=pflash,format=raw,file="$ovmf_vars"
      )
    else
      cp -f /usr/share/OVMF/OVMF_VARS_4M.fd "$ovmf_vars"
      qemu_args+=(
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
        -drive if=pflash,format=raw,file="$ovmf_vars"
      )
    fi
  fi

  # Boot Media / Disk configuration
  if [ "$disk_type" = "USB" ]; then
    qemu_args+=(
      -drive "id=usbdrive,file=$ISO,if=none,format=raw,readonly=on"
      -device "usb-storage,drive=usbdrive,bootindex=1"
    )
  else
    qemu_args+=(-cdrom "$ISO" -boot d)
  fi

  # Secondary virtual disk for storage if needed
  local test_disk="$VM/disk-$cfg_id.qcow2"
  if [ "$disk_type" = "NVMe" ]; then
    [ -f "$test_disk" ] || qemu-img create -f qcow2 "$test_disk" 10G >/dev/null
    qemu_args+=(
      -drive "file=$test_disk,if=none,id=nvm0,format=qcow2"
      -device "nvme,serial=alien-nvme-$cfg_id,drive=nvm0"
    )
  elif [ "$disk_type" = "SATA" ]; then
    [ -f "$test_disk" ] || qemu-img create -f qcow2 "$test_disk" 10G >/dev/null
    qemu_args+=(-drive "file=$test_disk,if=virtio,format=qcow2")
  fi

  local start_time
  start_time=$(date +%s)

  # Launch QEMU in background
  qemu-system-x86_64 "${qemu_args[@]}" &
  local qemu_pid=$!

  # Wait for QMP socket
  local timeout=120
  local elapsed=0
  while [ ! -S "$qmp_sock" ] && [ "$elapsed" -lt 15 ]; do
    sleep 0.5
    elapsed=$((elapsed + 1))
  done

  # Send Enter to boot immediately
  if [ -S "$qmp_sock" ]; then
    sleep 3.5
    python3 -c "import socket, json; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect('$qmp_sock'); s.recv(4096); s.sendall(b'{\"execute\": \"qmp_capabilities\"}\n'); s.recv(4096); s.sendall(b'{\"execute\": \"send-key\", \"arguments\": {\"keys\": [{\"type\": \"qcode\", \"data\": \"ret\"}]}}\n'); s.close()" 2>/dev/null || true
  fi

  # Monitor serial log for boot milestone
  local boot_done=0
  local boot_time=0
  local idle_ram_mb=0
  local max_wait=90

  for ((i=0; i<max_wait; i++)); do
    if [ -f "$serial_log" ]; then
      if grep -q -E "login:|Reached target Graphical Interface|Reached target Multi-User System|alien login:" "$serial_log" 2>/dev/null; then
        boot_time=$(( $(date +%s) - start_time ))
        boot_done=1
        echo "  Config $cfg_id reached target in ${boot_time}s"
        break
      fi
    fi
    if ! kill -0 "$qemu_pid" 2>/dev/null; then
      echo "  Config $cfg_id exited prematurely"
      break
    fi
    sleep 1
  done

  # Capture screenshot via QMP
  if [ -S "$qmp_sock" ]; then
    python3 "$ROOT/tests/capture-screenshot.py" "$screenshot" "$qmp_sock" 2>/dev/null || true
  fi

  # Clean up QEMU process
  if kill -0 "$qemu_pid" 2>/dev/null; then
    kill "$qemu_pid" 2>/dev/null || true
    wait "$qemu_pid" 2>/dev/null || true
  fi

  local status="FAIL"
  if [ "$boot_done" -eq 1 ]; then
    status="PASS"
  fi

  # Record results
  echo "RESULT: Config $cfg_id -> Status=$status, BootTime=${boot_time}s"
  echo "$cfg_id|$fw|$sb|$ram|$disk_type|$toram|$persist|$status|${boot_time}s|$screenshot" >> "$REPORTS/matrix-results.txt"
}

# Run tests
TARGET="${1:-all}"
rm -f "$REPORTS/matrix-results.txt"

if [ "$TARGET" = "all" ] || [ "$TARGET" = "1" ]; then
  run_config 1 "bios" "Off" 1024 "USB" "Off" "Off"
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "2" ]; then
  run_config 2 "bios" "Off" 4096 "SATA" "Off" "Off"
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "3" ]; then
  run_config 3 "uefi" "Off" 2048 "SATA" "Auto" "Off"
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "4" ]; then
  run_config 4 "uefi" "Off" 4096 "NVMe" "Auto" "Off"
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "5" ]; then
  run_config 5 "uefi" "On" 4096 "SATA" "Auto" "On"
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "6" ]; then
  run_config 6 "uefi" "Off" 8192 "NVMe" "Auto" "Off"
fi

echo "=== Compatibility Matrix Run Complete ==="
cat "$REPORTS/matrix-results.txt" 2>/dev/null || true
