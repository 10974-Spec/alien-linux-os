#!/usr/bin/env bash
# Alien — add a web app to the application menu
# Usage: ./add-webapp.sh "Name" "URL" "Icon Name or Path"
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 \"Name\" \"URL\" \"Icon\""
  echo "Example: $0 \"WhatsApp\" \"https://web.whatsapp.com\" \"whatsapp\""
  exit 1
fi

NAME="$1"
URL="$2"
ICON="$3"
CLASS="alien-webapp-${NAME,,}"
CLASS="${CLASS// /-}" # replace spaces with dashes

DESKTOP_FILE="$HOME/.local/share/applications/${CLASS}.desktop"
mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$NAME
Icon=$ICON
Exec=brave-browser --app="$URL" --class="$CLASS"
StartupWMClass=$CLASS
Terminal=false
Categories=Network;WebBrowser;
EOF

chmod +x "$DESKTOP_FILE"
echo "Added '$NAME' web app. It will appear in your launcher shortly."
