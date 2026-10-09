#!/usr/bin/env bash
# Alien — copy branding assets
set -euo pipefail

# Calamares assets
DEST_CAL="$WORK/config/includes.chroot/etc/calamares/branding/alien"
mkdir -p "$DEST_CAL"
cp "$SRC/branding/calamares/logo.svg" "$DEST_CAL/"
cp "$SRC/branding/calamares/welcome.png" "$DEST_CAL/"

echo "  - Copied branding assets"
