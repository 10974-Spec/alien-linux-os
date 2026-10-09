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



echo "  - Configured SDDM and Plymouth"
