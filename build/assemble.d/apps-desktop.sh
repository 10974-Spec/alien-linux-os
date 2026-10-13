#!/usr/bin/env bash
# Alien — Core application integration, MIME defaults, and directory skeletons
# Architecture: Real proven apps (VLC, lximage-qt, ghostwriter, featherpad, brave, store)
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

DEST_APPS="$WORK/config/includes.chroot/usr/share/applications"
DEST_BIN="$WORK/config/includes.chroot/usr/bin"
SKEL="$WORK/config/includes.chroot/etc/skel"
SKEL_CONFIG="$SKEL/.config"
SKEL_LXQT="$SKEL_CONFIG/lxqt"
mkdir -p "$DEST_APPS" "$DEST_BIN" "$SKEL/Notes" "$SKEL_LXQT"

# ─── 1. Alien Store & Utilities Desktop Entry ────────────────────────────────
cat > "$DEST_APPS/alien-store.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Alien Store
GenericName=Software Center
Comment=Browse, install, and update packages on Alien OS
Exec=alien-store
Icon=alien-store
StartupWMClass=alien-store
Categories=System;PackageManager;
Keywords=store;apps;install;software;package;synaptic;
StartupNotify=true
Terminal=false
EOF

# alias alien-add-ons command that simply opens the store
cat > "$DEST_BIN/alien-add-ons" <<'EOF'
#!/bin/sh
exec alien-store "$@"
EOF
chmod +x "$DEST_BIN/alien-add-ons"

# Ensure telegram-desktop and ghostwriter desktop links exist
ln -sf telegram-desktop.desktop "$DEST_APPS/telegramdesktop.desktop" 2>/dev/null || true
ln -sf org.kde.ghostwriter.desktop "$DEST_APPS/ghostwriter.desktop" 2>/dev/null || true

# ─── 2. System MIME Defaults (/etc/skel and /etc/xdg) ────────────────────────
MIME_FILE="$SKEL_CONFIG/mimeapps.list"
mkdir -p "$(dirname "$MIME_FILE")"

cat > "$MIME_FILE" <<'EOF'
[Default Applications]
video/mp4=vlc.desktop
video/x-matroska=vlc.desktop
video/webm=vlc.desktop
video/avi=vlc.desktop
video/quicktime=vlc.desktop
video/mpeg=vlc.desktop
video/x-flv=vlc.desktop
image/jpeg=lximage-qt.desktop
image/png=lximage-qt.desktop
image/gif=lximage-qt.desktop
image/webp=lximage-qt.desktop
image/svg+xml=lximage-qt.desktop
image/bmp=lximage-qt.desktop
image/tiff=lximage-qt.desktop
image/avif=lximage-qt.desktop
text/plain=featherpad.desktop
text/markdown=ghostwriter.desktop
text/x-markdown=ghostwriter.desktop
text/html=brave-browser.desktop
x-scheme-handler/http=brave-browser.desktop
x-scheme-handler/https=brave-browser.desktop
x-scheme-handler/about=brave-browser.desktop
x-scheme-handler/unknown=brave-browser.desktop
EOF

XDG_MIME="$WORK/config/includes.chroot/etc/xdg/mimeapps.list"
mkdir -p "$(dirname "$XDG_MIME")"
cp "$MIME_FILE" "$XDG_MIME"

echo "  - Integrated real core apps and system MIME defaults (VLC, lximage-qt, ghostwriter, featherpad, Brave)"
