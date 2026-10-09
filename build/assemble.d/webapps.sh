#!/usr/bin/env bash
# Alien — generates the pre-installed web apps for the ISO
# This script is called by build/inside-container.sh during the build.
set -euo pipefail

DEST="$WORK/config/includes.chroot/usr/share/applications"
mkdir -p "$DEST"

create_webapp() {
  local name="$1"
  local url="$2"
  local icon="$3"
  local class="alien-webapp-${name,,}"
  class="${class// /-}"

  cat > "$DEST/${class}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Icon=$icon
Exec=brave-browser --app="$url" --class="$class"
StartupWMClass=$class
Terminal=false
Categories=Network;WebBrowser;
EOF
  chmod +x "$DEST/${class}.desktop"
  echo "  - $name"
}

echo "Generating Web Apps..."
create_webapp "WhatsApp Web" "https://web.whatsapp.com" "whatsapp"
create_webapp "Instagram" "https://www.instagram.com" "instagram"
create_webapp "TikTok" "https://www.tiktok.com" "tiktok"
create_webapp "Chess.com" "https://www.chess.com" "chess"
create_webapp "Lichess" "https://lichess.org" "lichess"
create_webapp "YouTube" "https://www.youtube.com" "youtube"
create_webapp "Spotify" "https://open.spotify.com" "spotify-client"
create_webapp "Discord" "https://discord.com/app" "discord"
create_webapp "Netflix" "https://www.netflix.com" "netflix"
create_webapp "X" "https://x.com" "twitter"
create_webapp "Gmail" "https://mail.google.com" "gmail"
