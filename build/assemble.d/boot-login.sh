#!/usr/bin/env bash
# Alien — set up SDDM and Plymouth
set -euo pipefail

DEST_SDDM="$WORK/config/includes.chroot/etc/sddm.conf.d"
mkdir -p "$DEST_SDDM"

cat > "$DEST_SDDM/alien.conf" <<EOF
[Theme]
Current=breeze
CursorTheme=Bibata-Modern-Classic

[General]
InputMethod=
EOF



# Enable serial console autologin on ttyS0 for headless automated testing
DEST_SERIAL="$WORK/config/includes.chroot/etc/systemd/system/serial-getty@ttyS0.service.d"
mkdir -p "$DEST_SERIAL"
cat > "$DEST_SERIAL/autologin.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 115200 linux
EOF

echo "  - Configured SDDM, Plymouth, and serial console autologin"
