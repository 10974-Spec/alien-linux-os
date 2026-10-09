#!/usr/bin/env bash
set -e

# Directories
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../branding-assets" && pwd)"
OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generated"

mkdir -p "${OUT_DIR}/logos"
mkdir -p "${OUT_DIR}/icons/hicolor"
mkdir -p "${OUT_DIR}/backgrounds"
mkdir -p "${OUT_DIR}/plymouth"
mkdir -p "${OUT_DIR}/web"

# Dependencies check
if ! command -v convert &> /dev/null; then
    echo "ImageMagick (convert) is required. Please install it."
    exit 1
fi

echo "Generating assets into ${OUT_DIR}..."

# 1. Logo Main (PNGs and single colors)
for size in 64 128 256 512 1024; do
    convert -background none "${SRC_DIR}/logo-main.svg" -resize ${size}x${size} "${OUT_DIR}/logos/logo-main-${size}.png"
done

# Single color versions (white and dark)
convert -background none "${SRC_DIR}/logo-main.svg" -resize 512x512 -fill white -colorize 100 "${OUT_DIR}/logos/logo-main-white.png"
convert -background none "${SRC_DIR}/logo-main.svg" -resize 512x512 -fill "#2D2E3B" -colorize 100 "${OUT_DIR}/logos/logo-main-dark.png"

# 2. Logo2 / Dock Icon (alien-launcher)
cp "${SRC_DIR}/logo-bar.svg" "${OUT_DIR}/icons/alien-launcher.svg"
for size in 16 22 24 32 48 64 128 256 512; do
    mkdir -p "${OUT_DIR}/icons/hicolor/${size}x${size}/apps"
    convert -background none "${SRC_DIR}/logo-bar.svg" -resize ${size}x${size} "${OUT_DIR}/icons/hicolor/${size}x${size}/apps/alien-launcher.png"
done

# 3. Backgrounds
cp "${SRC_DIR}/bg/bg1.svg" "${OUT_DIR}/backgrounds/bg1-master.svg"
cp "${SRC_DIR}/bg/bg2.png" "${OUT_DIR}/backgrounds/bg2-master.png"

# Resizes and crops for backgrounds
for res in "1920x1080" "2560x1440" "3840x2160"; do
    convert "${SRC_DIR}/bg/bg1.svg" -resize ${res}^ -gravity center -extent ${res} "${OUT_DIR}/backgrounds/bg1-${res}.png"
    convert "${SRC_DIR}/bg/bg2.png" -resize ${res}^ -gravity center -extent ${res} "${OUT_DIR}/backgrounds/bg2-${res}.png"
done

# 4:3 and 16:10 crops
convert "${SRC_DIR}/bg/bg1.svg" -resize 1920x1200^ -gravity center -extent 1920x1200 "${OUT_DIR}/backgrounds/bg1-16x10.png"
convert "${SRC_DIR}/bg/bg1.svg" -resize 1600x1200^ -gravity center -extent 1600x1200 "${OUT_DIR}/backgrounds/bg1-4x3.png"

# Darkened-and-blurred login version
convert "${OUT_DIR}/backgrounds/bg1-1920x1080.png" -blur 0x12 -fill black -colorize 40% "${OUT_DIR}/backgrounds/bg-login.png"

# Boot menu versions (GRUB / syslinux)
convert "${SRC_DIR}/bg/bg1.svg" -resize 1024x768^ -gravity center -extent 1024x768 "${OUT_DIR}/backgrounds/bg-bootmenu-1024x768.png"
convert "${SRC_DIR}/bg/bg1.svg" -resize 1920x1080^ -gravity center -extent 1920x1080 "${OUT_DIR}/backgrounds/bg-bootmenu-1920x1080.png"

# 4. Plymouth frames
convert -background none "${SRC_DIR}/logo-main.svg" -resize 256x256 "${OUT_DIR}/plymouth/logo.png"

# 5. Web icons
convert -background none "${SRC_DIR}/logo-main.svg" -resize 32x32 "${OUT_DIR}/web/favicon.ico"
cp "${SRC_DIR}/logo-main.svg" "${OUT_DIR}/web/mark.svg"


# 7. Alien Icon Theme Overrides
ALIEN_ICON_DIR="${OUT_DIR}/icons/Alien"
mkdir -p "${ALIEN_ICON_DIR}"

cat > "${ALIEN_ICON_DIR}/index.theme" <<'EOF'
[Icon Theme]
Name=Alien
Comment=Alien OS Icon Theme - Overrides LXQt feather with Alien dock identity
Inherits=Papirus-Dark,Papirus,breeze-dark,hicolor
Directories=scalable/apps,scalable/places,scalable/panel,16x16/apps,22x22/apps,24x24/apps,32x32/apps,48x48/apps,64x64/apps,128x128/apps,256x256/apps,512x512/apps

[scalable/apps]
Size=512
MinSize=16
MaxSize=512
Type=Scalable

[scalable/places]
Size=512
MinSize=16
MaxSize=512
Type=Scalable

[scalable/panel]
Size=512
MinSize=16
MaxSize=512
Type=Scalable

[16x16/apps]
Size=16
Type=Fixed

[22x22/apps]
Size=22
Type=Fixed

[24x24/apps]
Size=24
Type=Fixed

[32x32/apps]
Size=32
Type=Fixed

[48x48/apps]
Size=48
Type=Fixed

[64x64/apps]
Size=64
Type=Fixed

[128x128/apps]
Size=128
Type=Fixed

[256x256/apps]
Size=256
Type=Fixed

[512x512/apps]
Size=512
Type=Fixed
EOF

# Copy logo2 (alien-launcher) into Alien icon theme under all feather and start-here names
for s in 16 22 24 32 48 64 128 256 512; do
    TDIR="${ALIEN_ICON_DIR}/${s}x${s}/apps"
    mkdir -p "$TDIR"
    SRC_ICON="${OUT_DIR}/icons/hicolor/${s}x${s}/apps/alien-launcher.png"
    if [ -f "$SRC_ICON" ]; then
        for name in alien-launcher lxqt lxqt-about desktop-environment-lxqt start-here start-here-lxqt distributor-logo distributor-logo-debian install-debian calamares; do
            cp "$SRC_ICON" "${TDIR}/${name}.png"
        done
    fi
done

# Scalable SVGs
mkdir -p "${ALIEN_ICON_DIR}/scalable/apps" "${ALIEN_ICON_DIR}/scalable/places" "${ALIEN_ICON_DIR}/scalable/panel"
for name in alien-launcher lxqt lxqt-about desktop-environment-lxqt start-here start-here-lxqt distributor-logo distributor-logo-debian install-debian calamares; do
    cp "${OUT_DIR}/icons/alien-launcher.svg" "${ALIEN_ICON_DIR}/scalable/apps/${name}.svg"
    cp "${OUT_DIR}/icons/alien-launcher.svg" "${ALIEN_ICON_DIR}/scalable/places/${name}.svg" 2>/dev/null || true
    cp "${OUT_DIR}/icons/alien-launcher.svg" "${ALIEN_ICON_DIR}/scalable/panel/${name}.svg" 2>/dev/null || true
done

# Create a contact sheet for preview
echo "Generating contact sheet..."
montage -label '%f' "${OUT_DIR}/logos/logo-main-256.png" "${OUT_DIR}/logos/logo-main-white.png" "${OUT_DIR}/logos/logo-main-dark.png" \
        "${OUT_DIR}/icons/hicolor/128x128/apps/alien-launcher.png" \
        "${OUT_DIR}/backgrounds/bg1-1920x1080.png" "${OUT_DIR}/backgrounds/bg-login.png" \
        -geometry 250x250+10+10 -background white -title "Alien OS Asset Contact Sheet" "${OUT_DIR}/contact_sheet.png"

cp "${OUT_DIR}/contact_sheet.png" "$(dirname "${BASH_SOURCE[0]}")/../docs/branding-screenshots/contact_sheet.png"

echo "Generation complete."
