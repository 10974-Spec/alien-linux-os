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

  # Estimated image size ~2000 MB, requirement: image * 1.5 + 512MB headroom = 3500 MB
  if [ "$mem_total_mb" -ge 3500 ]; then
    echo "Alien OS: Sufficient RAM (${mem_total_mb} MB >= 3500 MB). Enabling Copy-to-RAM."
    export TORAM="yes"
  else
    echo "Alien OS: Insufficient RAM for full copy-to-RAM (${mem_total_mb} MB < 3500 MB)."
    echo "Alien OS: Booting directly from boot media using Linux page cache."
    unset TORAM
  fi
fi
EOF
chmod +x "$DEST_INITRAMFS/alien-toram"

echo "  - Configured automatic RAM-fit logic for live boot"
