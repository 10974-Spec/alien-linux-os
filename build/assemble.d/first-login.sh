#!/usr/bin/env bash
# Alien — installs the first-login script into the autostart of the default user
set -euo pipefail

DEST="$WORK/config/includes.chroot/etc/skel/.config/autostart-scripts"
mkdir -p "$DEST"

cp "$SRC/tools/alien-scripts/first-login-setup.sh" "$DEST/"
chmod +x "$DEST/first-login-setup.sh"
echo "  - Added first-login-setup.sh to /etc/skel"
