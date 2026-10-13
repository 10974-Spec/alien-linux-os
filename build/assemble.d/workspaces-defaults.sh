#!/usr/bin/env bash
# Alien — configure workspaces and default apps
set -euo pipefail

DEST="$WORK/config/includes.chroot/etc/skel/.config"
mkdir -p "$DEST"

# 1. Workspaces (Virtual Desktops)
cat > "$DEST/kdeglobals" <<EOF
[KDE]
widgetStyle=Breeze

[KDE Action Restrictions]
plasma-desktop/add_widget=false

[KScreen]
ScreenScaleFactors=eDP-1=1;DP-1=1;DP-2=1;HDMI-1=1;HDMI-2=1;
EOF

cat > "$DEST/kwinrc" <<EOF
[Desktops]
Number=4
Name_1=Chill
Name_2=Social
Name_3=Chess
Name_4=Movies/Media

[ModifierOnlyShortcuts]
Meta=org.kde.plasma.kickoff,org.kde.plasma.kickoff,toggleDashboard

[Windows]
BorderlessMaximizedWindows=true
Placement=Centered
RollOverDesktops=true
TitleButtonsLeft=
TitleButtonsRight=HIAX

[org.kde.kdecoration2]
BorderSize=Normal
Theme=Breeze
EOF

cat > "$DEST/kglobalshortcutsrc" <<EOF
[kwin]
Switch to Desktop 1=Meta+1,Meta+F1,Switch to Desktop 1
Switch to Desktop 2=Meta+2,Meta+F2,Switch to Desktop 2
Switch to Desktop 3=Meta+3,Meta+F3,Switch to Desktop 3
Switch to Desktop 4=Meta+4,Meta+F4,Switch to Desktop 4
EOF

# 2. Touchpad defaults (tap to click)
cat > "$DEST/kcminputrc" <<EOF
[Libinput/1739/0/Synaptics TM3276-022]
ClickMethod=2
NaturalScroll=false
ScrollMethod=1
TapToClick=true
EOF

# 3. Default Applications are centrally managed by apps-desktop.sh

# 4. Window Rules (open apps on specific workspaces)
cat > "$DEST/kwinrulesrc" <<EOF
[1]
Description=Chill Workspace
clientmachine=localhost
desktop=1
desktoprule=2
wmclass=elisa
wmclassmatch=1

[2]
Description=Social Workspace
clientmachine=localhost
desktop=2
desktoprule=2
wmclass=telegram-desktop
wmclassmatch=1

[3]
Description=Chess Workspace
clientmachine=localhost
desktop=3
desktoprule=2
wmclass=EnCroissant
wmclassmatch=1

[4]
Description=Movies Workspace
clientmachine=localhost
desktop=4
desktoprule=2
wmclass=mpv
wmclassmatch=1
EOF

echo "  - Configured workspaces, touchpads, default apps, and window rules"
