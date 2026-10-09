#!/usr/bin/env bash
# Alien — install the global Look-and-Feel theme
set -euo pipefail

DEST="$WORK/config/includes.chroot/usr/share/plasma/look-and-feel"
mkdir -p "$DEST"

cp -a "$SRC/theme/look-and-feel/alien-theme" "$DEST/"
echo "  - Copied alien-theme Look-and-Feel package"
