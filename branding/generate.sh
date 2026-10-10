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
if ! command -v convert &>/dev/null; then
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

cat >"${ALIEN_ICON_DIR}/index.theme" <<'EOF'
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

# 8. Terminal Banner Art
echo "Generating terminal banner art..."
BANNER_DIR="${OUT_DIR}/banner"
mkdir -p "${BANNER_DIR}"

# 8.1 Base PNGs (logo-pixel and head-pixel)
convert -background none "${SRC_DIR}/logo-main.svg" -resize 1024x1024 -trim +repage "${BANNER_DIR}/logo-pixel.png"
convert "${BANNER_DIR}/logo-pixel.png" -gravity North -crop 100x64%+0+0 -trim +repage "${BANNER_DIR}/head-pixel.png"

# 8.2 Sticker panels and transparent variants
convert "${BANNER_DIR}/logo-pixel.png" -bordercolor white -border 24 -background white -flatten "${BANNER_DIR}/logo-sticker.png"
convert "${BANNER_DIR}/head-pixel.png" -bordercolor white -border 16 -background white -flatten "${BANNER_DIR}/head-sticker.png"
cp "${BANNER_DIR}/logo-pixel.png" "${BANNER_DIR}/logo-transparent.png"
cp "${BANNER_DIR}/head-pixel.png" "${BANNER_DIR}/head-transparent.png"

# 8.3 ANSI art generation (using chafa)
if command -v chafa &>/dev/null; then
	# Full logo (truecolor, 256-color)
	chafa --size 44x22 -c full --symbols block,border,space --dither none "${BANNER_DIR}/logo-sticker.png" >"${BANNER_DIR}/logo-full-sticker.ans"
	chafa --size 44x22 -c full --symbols block,border,space --dither none "${BANNER_DIR}/logo-transparent.png" >"${BANNER_DIR}/logo-full-transparent.ans"
	cp "${BANNER_DIR}/logo-full-sticker.ans" "${BANNER_DIR}/logo-full.ans"

	chafa --size 44x22 -c 256 --symbols block,border,space --dither none "${BANNER_DIR}/logo-sticker.png" >"${BANNER_DIR}/logo-full-256-sticker.ans"
	chafa --size 44x22 -c 256 --symbols block,border,space --dither none "${BANNER_DIR}/logo-transparent.png" >"${BANNER_DIR}/logo-full-256-transparent.ans"
	cp "${BANNER_DIR}/logo-full-256-sticker.ans" "${BANNER_DIR}/logo-full-256.ans"

	# Compact head logo (truecolor, transparent, sticker)
	chafa --size 24x12 -c full --symbols block,border,space --dither none "${BANNER_DIR}/head-sticker.png" >"${BANNER_DIR}/logo-compact-sticker.ans"
	chafa --size 24x12 -c full --symbols block,border,space --dither none "${BANNER_DIR}/head-transparent.png" >"${BANNER_DIR}/logo-compact-transparent.ans"
	cp "${BANNER_DIR}/logo-compact-sticker.ans" "${BANNER_DIR}/logo-compact.ans"

	# 16-color for Linux console
	chafa --size 24x12 -c 16 --symbols block,border,space --dither none "${BANNER_DIR}/head-transparent.png" >"${BANNER_DIR}/logo-16.ans"

	# Sixel version
	chafa --format=sixels --size 240x240 "${BANNER_DIR}/logo-sticker.png" >"${BANNER_DIR}/logo-pixel.six" 2>/dev/null || true
else
	echo "Notice: chafa not found on host, relying on container/pre-generated banner art."
fi

# 9. GRUB Graphical Theme
echo "Generating GRUB theme assets..."
GRUB_DIR="${OUT_DIR}/grub"
mkdir -p "${GRUB_DIR}/icons"

# Background (1920x1080 darkened)
if [ -f "${OUT_DIR}/backgrounds/bg1-1920x1080.png" ]; then
	convert "${OUT_DIR}/backgrounds/bg1-1920x1080.png" \
		-modulate 60,70,100 \
		-fill "#050814" -colorize 40% \
		"${GRUB_DIR}/background.png"
fi

# Selection bar pixmaps
convert -size 400x36 xc:"#2a324b" -bordercolor "#4F8EF7" -border 1 "${GRUB_DIR}/select_c.png"

# Progress bar
convert -size 400x14 xc:"#161925" -bordercolor "#3d4455" -border 1 "${GRUB_DIR}/progress_frame_c.png"
convert -size 400x14 xc:"#4F8EF7" "${GRUB_DIR}/progress_hl_c.png"

# Fonts
if command -v grub-mkfont >/dev/null 2>&1; then
	for font in /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /usr/share/fonts/dejavu/DejaVuSans.ttf; do
		if [ -f "$font" ]; then
			grub-mkfont -s 12 -o "${GRUB_DIR}/dejavu-12.pf2" "$font" 2>/dev/null || true
			grub-mkfont -s 14 -o "${GRUB_DIR}/dejavu-14.pf2" "$font" 2>/dev/null || true
			break
		fi
	done
	for font_bold in /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf /usr/share/fonts/dejavu/DejaVuSans-Bold.ttf; do
		if [ -f "$font_bold" ]; then
			grub-mkfont -s 14 -o "${GRUB_DIR}/dejavu-bold-14.pf2" "$font_bold" 2>/dev/null || true
			break
		fi
	done
fi

# Icons
if [ -f "${BANNER_DIR}/head-sticker.png" ]; then
	convert "${BANNER_DIR}/head-sticker.png" -resize 32x32 -gravity center -extent 32x32 "${GRUB_DIR}/icons/alien.png"
	cp "${GRUB_DIR}/icons/alien.png" "${GRUB_DIR}/icons/gnu-linux.png"
	cp "${GRUB_DIR}/icons/alien.png" "${GRUB_DIR}/icons/linux.png"
fi

convert -size 32x32 xc:none -fill "#4F8EF7" -draw "circle 16,16 16,3" -fill "#050814" -draw "circle 16,16 16,6" -stroke "#4F8EF7" -strokewidth 2 -draw "line 16,8 16,16 line 16,16 22,16" "${GRUB_DIR}/icons/snapshots.png"
cp "${GRUB_DIR}/icons/snapshots.png" "${GRUB_DIR}/icons/snapshot.png"

convert -size 32x32 xc:none -stroke "#2ECC71" -strokewidth 2 -fill none -draw "rectangle 4,8 28,24" -fill "#2ECC71" -draw "rectangle 7,12 11,20 rectangle 14,12 18,20 rectangle 21,12 25,20" "${GRUB_DIR}/icons/memtest.png"
cp "${GRUB_DIR}/icons/memtest.png" "${GRUB_DIR}/icons/memtest86+.png"

convert -size 32x32 xc:none -stroke "#F1C40F" -strokewidth 2 -fill none -draw "circle 16,16 16,7" -fill "#F1C40F" -draw "circle 16,16 16,11" "${GRUB_DIR}/icons/firmware.png"
cp "${GRUB_DIR}/icons/firmware.png" "${GRUB_DIR}/icons/uefi-firmware.png"

convert -size 32x32 xc:none -stroke "#E74C3C" -strokewidth 2 -fill none -draw "circle 16,16 16,6" -stroke "#050814" -strokewidth 4 -draw "line 16,4 16,12" -stroke "#E74C3C" -strokewidth 2 -draw "line 16,4 16,12" "${GRUB_DIR}/icons/shutdown.png"
cp "${GRUB_DIR}/icons/shutdown.png" "${GRUB_DIR}/icons/halt.png"

convert -size 32x32 xc:none -stroke "#4F8EF7" -strokewidth 2 -fill none -draw "circle 16,16 16,7" -fill "#4F8EF7" -draw "polygon 16,4 22,7 16,10" "${GRUB_DIR}/icons/reboot.png"

convert -size 32x32 xc:none -stroke "#F1C40F" -strokewidth 2 -fill none -draw "polygon 16,4 4,28 28,28" -fill "#F1C40F" -draw "line 16,12 16,20 point 16,24" "${GRUB_DIR}/icons/recovery.png"
cp "${GRUB_DIR}/icons/recovery.png" "${GRUB_DIR}/icons/safe.png"

convert -size 32x32 xc:none -stroke "#CDD6F4" -strokewidth 2 -fill none -draw "line 6,26 26,6 circle 22,10 22,6" "${GRUB_DIR}/icons/tools.png"

# theme.txt
cat > "${GRUB_DIR}/theme.txt" <<'EOF'
# Alien OS GRUB Theme
title-text: ""
desktop-image: "background.png"
desktop-color: "#050814"
terminal-font: "DejaVu Sans Regular 14"

+ boot_menu {
  left = 20%
  top = 28%
  width = 60%
  height = 50%
  item_font = "DejaVu Sans Regular 14"
  item_color = "#cdd6f4"
  selected_item_font = "DejaVu Sans Bold 14"
  selected_item_color = "#ffffff"
  selected_item_pixmap_style = "select_c.png"
  icon_width = 32
  icon_height = 32
  item_height = 38
  item_padding = 6
  item_spacing = 8
}

+ progress_bar {
  id = "__timeout__"
  left = 20%
  top = 82%
  width = 60%
  height = 14
  font = "DejaVu Sans Regular 12"
  text_color = "#a6adc8"
  bar_style = "progress_frame_c.png"
  highlight_style = "progress_hl_c.png"
}

+ label {
  top = 88%
  left = 20%
  width = 60%
  height = 20
  text = "Use arrow keys to select, Enter to boot, 'e' to edit, 'c' for CLI."
  font = "DejaVu Sans Regular 12"
  color = "#6c7086"
  align = "center"
}
EOF

# Create a contact sheet for preview
echo "Generating contact sheet..."
montage -label '%f' "${OUT_DIR}/logos/logo-main-256.png" "${OUT_DIR}/logos/logo-main-white.png" "${OUT_DIR}/logos/logo-main-dark.png" \
	"${OUT_DIR}/icons/hicolor/128x128/apps/alien-launcher.png" \
	"${OUT_DIR}/backgrounds/bg1-1920x1080.png" "${OUT_DIR}/backgrounds/bg-login.png" \
	-geometry 250x250+10+10 -background white -title "Alien OS Asset Contact Sheet" "${OUT_DIR}/contact_sheet.png"

cp "${OUT_DIR}/contact_sheet.png" "$(dirname "${BASH_SOURCE[0]}")/../docs/branding-screenshots/contact_sheet.png"

echo "Generation complete."

