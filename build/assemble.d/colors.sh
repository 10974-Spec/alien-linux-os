#!/usr/bin/env bash
# Alien — generates the Plasma color schemes from the master accent color
set -euo pipefail

DEST="$WORK/config/includes.chroot/usr/share/color-schemes"
mkdir -p "$DEST"

# Read the accent color from the master config, fallback to blue
ACCENT="#4F8EF7"

# Extract RGB components
R=$(printf "%d" 0x${ACCENT:1:2})
G=$(printf "%d" 0x${ACCENT:3:2})
B=$(printf "%d" 0x${ACCENT:5:2})
RGB="$R,$G,$B"

cat > "$DEST/AlienLight.colors" <<EOF
[Color Scheme]
Name=Alien Light
[Colors:Button]
BackgroundNormal=240,240,240
DecorationFocus=$RGB
DecorationHover=$RGB
ForegroundNormal=35,38,41
[Colors:Selection]
BackgroundNormal=$RGB
ForegroundNormal=255,255,255
[Colors:View]
BackgroundNormal=252,252,252
ForegroundNormal=35,38,41
DecorationFocus=$RGB
DecorationHover=$RGB
[Colors:Window]
BackgroundNormal=245,245,245
ForegroundNormal=35,38,41
DecorationFocus=$RGB
DecorationHover=$RGB
EOF

cat > "$DEST/AlienDark.colors" <<EOF
[Color Scheme]
Name=Alien Dark
[Colors:Button]
BackgroundNormal=49,54,59
DecorationFocus=$RGB
DecorationHover=$RGB
ForegroundNormal=239,240,241
[Colors:Selection]
BackgroundNormal=$RGB
ForegroundNormal=255,255,255
[Colors:View]
BackgroundNormal=35,38,41
ForegroundNormal=239,240,241
DecorationFocus=$RGB
DecorationHover=$RGB
[Colors:Window]
BackgroundNormal=42,46,50
ForegroundNormal=239,240,241
DecorationFocus=$RGB
DecorationHover=$RGB
EOF

echo "  - Generated AlienLight and AlienDark color schemes with accent $ACCENT ($RGB)"
