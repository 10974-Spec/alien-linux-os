#!/usr/bin/env bash
# Alien — configure autostart apps
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

DEST="$WORK/config/includes.chroot/etc/skel/.config/autostart"
mkdir -p "$DEST"

# alien-panel-migrate: autostart so existing users get new panel pins added once
cat > "$DEST/alien-panel-migrate.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Alien Panel Migration
Comment=Adds new default panel pins for existing users
Exec=alien-panel-migrate
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

echo "  - Configured autostart (alien-panel-migrate)"
