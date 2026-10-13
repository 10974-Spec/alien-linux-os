#!/usr/bin/env bash
# Alien — install in-guest selftest assets and inert autostart launcher
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

DEST_ASSETS="$WORK/config/includes.chroot/usr/share/alien/selftest"
DEST_AUTOSTART="$WORK/config/includes.chroot/etc/skel/.config/autostart"
mkdir -p "$DEST_ASSETS" "$DEST_AUTOSTART"

# Copy tiny selftest media assets (<30KB)
if [ -d "$SRC/tests/selftest-assets" ]; then
    cp -a "$SRC"/tests/selftest-assets/* "$DEST_ASSETS/"
fi

# Inert autostart: only runs if kernel parameter 'alien.selftest=1' is present
cat > "$DEST_AUTOSTART/alien-guest-selftest.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Alien Guest Selftest
Comment=Automated verification runner (active only with alien.selftest=1)
Exec=bash -c "if grep -q 'alien.selftest=1' /proc/cmdline 2>/dev/null; then sleep 3 && /usr/bin/alien-guest-selftest; fi"
Terminal=false
Hidden=false
NoDisplay=true
X-LXQt-Need-Tray=false
EOF

echo "  - Installed selftest media assets and inert autostart entry"
