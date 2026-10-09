#!/usr/bin/env bash
# Alien — configure autostart apps
set -euo pipefail

DEST="$WORK/config/includes.chroot/etc/skel/.config/autostart"
mkdir -p "$DEST"

# Autostart Telegram
cat > "$DEST/org.telegram.desktop.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Telegram Desktop
Comment=Official desktop application for the Telegram messaging service
Exec=telegram-desktop %u -startintray
Icon=telegram
Path=
Terminal=false
Categories=Network;InstantMessaging;Qt;
EOF

# Autostart WhatsApp Web App
cat > "$DEST/alien-webapp-whatsapp-web.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=WhatsApp Web
Icon=whatsapp
Exec=brave-browser --app="https://web.whatsapp.com" --class="alien-webapp-whatsapp-web"
StartupWMClass=alien-webapp-whatsapp-web
Terminal=false
Categories=Network;WebBrowser;
EOF

echo "  - Configured autostart apps (Telegram, WhatsApp)"
