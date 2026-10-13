#!/usr/bin/env bash
# Alien OS — Automatic RAM-fit logic for live boot (Phase 5)
set -euo pipefail

DEST_INITRAMFS="$WORK/config/includes.chroot/etc/initramfs-tools/scripts/live-premount"
mkdir -p "$DEST_INITRAMFS"

cat > "$DEST_INITRAMFS/alien-toram" <<'EOF'
#!/bin/sh
# Check if alien.toram=auto is set on kernel command line
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in prereqs) prereqs; exit 0;; esac

if grep -q "alien.toram=auto" /proc/cmdline 2>/dev/null; then
  # Calculate RAM in MB
  mem_total_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  mem_total_mb=$((mem_total_kb / 1024))

  # Detect image size if mounted, otherwise default to 2048 MB
  image_mb=2048
  for sq in /run/live/medium/live/*.squashfs /run/live/findiso/live/*.squashfs /lib/live/mount/medium/live/*.squashfs; do
    if [ -f "$sq" ]; then
      image_bytes="$(wc -c < "$sq" 2>/dev/null || echo 0)"
      image_mb=$((image_bytes / 1048576))
      break
    fi
  done

  # Required formula: image size x 1.5 + 512 MB headroom
  needed_mb=$(( (image_mb * 3 / 2) + 512 ))

  if [ "$mem_total_mb" -ge "$needed_mb" ]; then
    echo "Alien OS: Sufficient RAM (${mem_total_mb} MB >= required ${needed_mb} MB for ${image_mb} MB image). Enabling Copy-to-RAM."
    export TORAM="yes"
  else
    echo "Alien OS: Insufficient RAM for full copy-to-RAM (${mem_total_mb} MB < required ${needed_mb} MB for ${image_mb} MB image)."
    echo "Alien OS: Booting directly from boot media using Linux page cache."
    unset TORAM
  fi
fi
EOF
chmod +x "$DEST_INITRAMFS/alien-toram"

echo "  - Configured automatic RAM-fit logic for live boot"
