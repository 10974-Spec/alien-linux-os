#!/usr/bin/env bash
# Alien — Desktop and Identity Branding (Phases 5 & 6)
set -euo pipefail

source "$SRC/branding/tokens.env"

# --- Phase 5: Desktop ---

# 1. Wallpapers
DEST_BG="$WORK/config/includes.chroot/usr/share/backgrounds"
mkdir -p "$DEST_BG"
cp "$SRC/branding/generated/backgrounds/bg1-master.svg" "$DEST_BG/alien-bg1.svg"
cp "$SRC/branding/generated/backgrounds/bg1-1920x1080.png" "$DEST_BG/alien-bg1.png"
cp "$SRC/branding/generated/backgrounds/bg2-master.png" "$DEST_BG/alien-bg2.png"

# Register Plasma wallpapers (Full)
DEST_PLASMA_BG="$WORK/config/includes.chroot/usr/share/wallpapers/AlienBG1"
mkdir -p "$DEST_PLASMA_BG/contents/images"
cp "$SRC/branding/generated/backgrounds/bg1-1920x1080.png" "$DEST_PLASMA_BG/contents/images/1920x1080.png"
cat > "$DEST_PLASMA_BG/metadata.desktop" <<EOF
[Desktop Entry]
Name=Alien Default
X-KDE-PluginInfo-Name=AlienBG1
X-KDE-PluginInfo-Author=Alien
X-KDE-PluginInfo-Email=
X-KDE-PluginInfo-License=GPLv3
EOF

# 2. Launcher/Home Button Icon
DEST_ICONS="$WORK/config/includes.chroot/usr/share/icons/hicolor"
mkdir -p "$DEST_ICONS"
cp -r "$SRC/branding/generated/icons/hicolor/"* "$DEST_ICONS/"

# Add override for Papirus (if installed)
DEST_PAPIRUS="$WORK/config/includes.chroot/usr/share/icons/Papirus/64x64/places"
mkdir -p "$DEST_PAPIRUS"
cp "$SRC/branding/generated/icons/hicolor/64x64/apps/alien-launcher.png" "$DEST_PAPIRUS/start-here.png" || true
cp "$SRC/branding/generated/icons/hicolor/64x64/apps/alien-launcher.png" "$DEST_PAPIRUS/distributor-logo.png" || true

# 3. Fonts and Theme Settings
DEST_FONTS="$WORK/config/includes.chroot/etc/fonts/conf.d"
mkdir -p "$DEST_FONTS"
cat > "$DEST_FONTS/99-alien-fonts.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer><family>${FONT_UI}</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>${FONT_MONO}</family></prefer>
  </alias>
</fontconfig>
EOF

# KDE Font configuration
DEST_KDE="$WORK/config/includes.chroot/etc/skel/.config"
mkdir -p "$DEST_KDE"
cat > "$DEST_KDE/kdeglobals" <<EOF
[General]
font=${FONT_UI},10,-1,5,50,0,0,0,0,0
fixed=${FONT_MONO},10,-1,5,50,0,0,0,0,0
EOF

# Replace ALIEN_ACCENT in colors.sh with the one from tokens.env
sed -i "s|ACCENT=.*|ACCENT=\"${COLOR_ACCENT}\"|" "$SRC/build/assemble.d/colors.sh" || true


# --- Phase 6: System Identity ---

# 1. os-release and issue
DEST_OS="$WORK/config/includes.chroot/etc"
mkdir -p "$DEST_OS"

cat > "$DEST_OS/os-release" <<EOF
PRETTY_NAME="${OS_NAME} @ALIEN_EDITION_CAPITALIZED@ @ALIEN_VERSION@"
NAME="${OS_NAME}"
VERSION_ID="@ALIEN_VERSION@"
VERSION="@ALIEN_VERSION@"
VERSION_CODENAME="@ALIEN_ID@"
ID=@ALIEN_ID@
ID_LIKE=debian
HOME_URL="https://github.com/alien-os"
EOF

cat > "$DEST_OS/lsb-release" <<EOF
DISTRIB_ID="${OS_NAME}"
DISTRIB_RELEASE="@ALIEN_VERSION@"
DISTRIB_CODENAME="@ALIEN_ID@"
DISTRIB_DESCRIPTION="${OS_NAME} @ALIEN_EDITION_CAPITALIZED@ @ALIEN_VERSION@"
EOF

cat > "$DEST_OS/issue" <<EOF
${OS_NAME} @ALIEN_EDITION_CAPITALIZED@ @ALIEN_VERSION@ \n \l

EOF

cat > "$DEST_OS/issue.net" <<EOF
${OS_NAME} @ALIEN_EDITION_CAPITALIZED@ @ALIEN_VERSION@
EOF

cat > "$DEST_OS/motd" <<EOF

   Welcome to ${OS_NAME} @ALIEN_EDITION_CAPITALIZED@!
   Version: @ALIEN_VERSION@

EOF

# Terminal bashrc branded banner
cat >> "$DEST_OS/bash.bashrc" <<'EOF'
if [ -n "$PS1" ]; then
  # Simple banner for Alien
  echo -e "\033[1;34m"
  echo "    /\ "
  echo "   /  \    Alien OS"
  echo "  /____\   Your world, your way."
  echo -e "\033[0m"
fi
EOF

# Installer (Calamares) Slideshow
DEST_CAL="$WORK/config/includes.chroot/etc/calamares/branding/alien"
mkdir -p "$DEST_CAL"

# Modify branding.desc to use variables and add slideshow
cat > "$DEST_CAL/branding.desc" <<EOF
---
componentName:  alien

strings:
    productName:         ${OS_NAME}
    shortProductName:    ${OS_NAME}
    version:             @ALIEN_VERSION@
    shortVersion:        @ALIEN_VERSION@
    versionedName:       ${OS_NAME} @ALIEN_VERSION@
    shortVersionedName:  ${OS_NAME} @ALIEN_VERSION@
    bootloaderEntryName: ${OS_NAME}

images:
    productLogo:         "logo.png"
    productIcon:         "logo.png"
    productWelcome:      "logo.png"

slideshow:               "show.qml"

style:
   sidebarBackground:    "${COLOR_DARK_SHADE}"
   sidebarText:          "${COLOR_LIGHT_NEUTRAL}"
   sidebarTextSelect:    "${COLOR_ACCENT}"
   sidebarTextHighlight: "${COLOR_ACCENT}"
EOF

# Minimal QML Slideshow
cat > "$DEST_CAL/show.qml" <<EOF
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation
    width: 800; height: 400

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Text {
            anchors.centerIn: parent
            text: "Welcome to ${OS_NAME}"
            color: "${COLOR_ACCENT}"
            font.pixelSize: 32
        }
    }
    Slide {
        Text {
            anchors.centerIn: parent
            text: "Fast, Lightweight, and Yours."
            color: "${COLOR_LIGHT_NEUTRAL}"
            font.pixelSize: 24
        }
    }
    Slide {
        Text {
            anchors.centerIn: parent
            text: "Thank you for installing ${OS_NAME}!"
            color: "${COLOR_SUCCESS}"
            font.pixelSize: 24
        }
    }
}
EOF

# Disable old branding.sh script if we have completely replaced it
rm -f "$SRC/build/assemble.d/branding.sh"

echo "  - Applied Desktop and Identity Branding"
