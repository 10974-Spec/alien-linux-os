#!/usr/bin/env bash
# Alien — Preseed LXQt defaults, Openbox, themes, wallpaper, and Alien identity
set -euo pipefail

source "$SRC/branding/tokens.env"

# 1. Directories for system-wide defaults (/etc/xdg) and new users (/etc/skel/.config)
ETC_LXQT="$WORK/config/includes.chroot/etc/xdg/lxqt"
ETC_PCMANFM="$WORK/config/includes.chroot/etc/xdg/pcmanfm-qt/lxqt"
ETC_OPENBOX="$WORK/config/includes.chroot/etc/xdg/openbox"
ETC_AUTOSTART="$WORK/config/includes.chroot/etc/xdg/autostart"

SKEL_LXQT="$WORK/config/includes.chroot/etc/skel/.config/lxqt"
SKEL_PCMANFM="$WORK/config/includes.chroot/etc/skel/.config/pcmanfm-qt/lxqt"
SKEL_OPENBOX="$WORK/config/includes.chroot/etc/skel/.config/openbox"
SKEL_AUTOSTART="$WORK/config/includes.chroot/etc/skel/.config/autostart"
SKEL_ALIEN="$WORK/config/includes.chroot/etc/skel/.config/alien"

mkdir -p "$ETC_LXQT" "$ETC_PCMANFM" "$ETC_OPENBOX" "$ETC_AUTOSTART"
mkdir -p "$SKEL_LXQT" "$SKEL_PCMANFM" "$SKEL_OPENBOX" "$SKEL_AUTOSTART" "$SKEL_ALIEN"

# Ensure Alien wallpaper is in backgrounds
DEST_BG="$WORK/config/includes.chroot/usr/share/backgrounds"
mkdir -p "$DEST_BG"
if [ -f "$SRC/branding/generated/backgrounds/bg1-1920x1080.png" ]; then
    cp "$SRC/branding/generated/backgrounds/bg1-1920x1080.png" "$DEST_BG/alien-bg1.png"
fi

# Ensure alien-launcher icon exists in hicolor and scalable
DEST_ICONS="$WORK/config/includes.chroot/usr/share/icons/hicolor"
mkdir -p "$DEST_ICONS/scalable/apps" "$DEST_ICONS/64x64/apps"
if [ -f "$SRC/branding-assets/logo-bar.svg" ]; then
    cp "$SRC/branding-assets/logo-bar.svg" "$DEST_ICONS/scalable/apps/alien-launcher.svg"
fi
if [ -f "$SRC/branding/generated/icons/hicolor/64x64/apps/alien-launcher.png" ]; then
    cp "$SRC/branding/generated/icons/hicolor/64x64/apps/alien-launcher.png" "$DEST_ICONS/64x64/apps/alien-launcher.png"
fi

# -----------------------------------------------------------------------------
# A. Install Alien Icon Theme (inheriting Papirus-Dark, overriding feather)
# -----------------------------------------------------------------------------
DEST_ALIEN_ICON="$WORK/config/includes.chroot/usr/share/icons/Alien"
mkdir -p "$DEST_ALIEN_ICON"
if [ -d "$SRC/branding/generated/icons/Alien" ]; then
    cp -a "$SRC/branding/generated/icons/Alien/"* "$DEST_ALIEN_ICON/"
fi


# -----------------------------------------------------------------------------
# C. session.conf (preseed window_manager=openbox)
# -----------------------------------------------------------------------------
cat > "$ETC_LXQT/session.conf" <<EOF
[General]
window_manager=openbox
leave_confirmation=false

[Environment]
BROWSER=brave-browser
TERM=qterminal
GTK_CSD=0
GTK_OVERLAY_SCROLLING=0

[Mouse]
cursor_theme=Bibata-Modern-Classic
cursor_size=24
acc_factor=20
acc_threshold=10
left_handed=false

[Keyboard]
delay=500
interval=30
beep=false

[Font]
antialias=true
hinting=true
dpi=96
EOF
cp -a "$ETC_LXQT/session.conf" "$SKEL_LXQT/session.conf"

# -----------------------------------------------------------------------------
# D. lxqt.conf (theme, icons, cursor, fonts from tokens.env)
# -----------------------------------------------------------------------------
cat > "$ETC_LXQT/lxqt.conf" <<EOF
[General]
theme=alien
icon_theme=Alien
icon_follow_color_scheme=false
single_click_activate=false
tool_button_style=ToolButtonTextBesideIcon
palette_override=true
cursor_theme=Bibata-Modern-Classic
cursor_size=24

[Mouse]
cursor_theme=Bibata-Modern-Classic
cursor_size=24

[Qt]
style=Fusion
font="${FONT_UI},10,-1,5,50,0,0,0,0,0"
fixedFont="${FONT_MONO},10,-1,5,50,0,0,0,0,0"
doubleClickInterval=400
wheelScrollLines=3
EOF
cp -a "$ETC_LXQT/lxqt.conf" "$SKEL_LXQT/lxqt.conf"

# -----------------------------------------------------------------------------
# E. pcmanfm-qt settings.conf (wallpaper and stretch mode)
# -----------------------------------------------------------------------------
cat > "$ETC_PCMANFM/settings.conf" <<EOF
[Desktop]
DesktopShortcuts=Home, Trash, Computer, Network
Wallpaper=/usr/share/backgrounds/alien-bg1.png
WallpaperMode=stretch
WallpaperRandomize=false

[System]
Archiver=lxqt-archiver
FallbackIconThemeName=Papirus
Terminal=qterminal

[Window]
AlwaysShowTabs=true
EOF
cp -a "$ETC_PCMANFM/settings.conf" "$SKEL_PCMANFM/settings.conf"

# -----------------------------------------------------------------------------
# F. Full-Width Bottom LXQt Panel
# -----------------------------------------------------------------------------
cat > "$ETC_LXQT/panel.conf" <<EOF
[General]
iconTheme=Alien

[panel1]
plugins=mainmenu, showdesktop, desktopswitch, quicklaunch, taskbar, kbindicator, tray, statusnotifier, mount, volume, worldclock, quicklaunch2
position=Bottom
desktop=0
panelSize=32
iconSize=24

[mainmenu]
alignment=Left
icon=/usr/share/icons/hicolor/64x64/apps/alien-launcher.png
ownIcon=true
type=fancymenu

[fancymenu]
alignment=Left
icon=/usr/share/icons/hicolor/64x64/apps/alien-launcher.png
ownIcon=true
type=fancymenu

[showdesktop]
alignment=Left
type=showdesktop

[desktopswitch]
alignment=Left
type=desktopswitch

[quicklaunch]
alignment=Left
apps\1\desktop=/usr/share/applications/pcmanfm-qt.desktop
apps\2\desktop=/usr/share/applications/qterminal.desktop
apps\3\desktop=/usr/share/applications/featherpad.desktop
apps\4\desktop=/usr/share/applications/alien-app-center.desktop
apps\5\desktop=/usr/share/applications/code.desktop
apps\size=5
type=quicklaunch

[taskbar]
alignment=Left
buttonWidth=200
raiseOnCurrentDesktop=true
type=taskbar

[kbindicator]
alignment=Right
type=kbindicator

[tray]
alignment=Right
type=tray

[statusnotifier]
alignment=Right
type=statusnotifier

[mount]
alignment=Right
type=mount

[volume]
alignment=Right
device=0
type=volume

[worldclock]
alignment=Right
type=worldclock

[quicklaunch2]
alignment=Right
apps\1\desktop=/usr/share/applications/lxqt-leave.desktop
apps\size=1
type=quicklaunch
EOF
cp -a "$ETC_LXQT/panel.conf" "$SKEL_LXQT/panel.conf"

# -----------------------------------------------------------------------------
# G. Openbox config (rc.xml and autostart with picom)
# -----------------------------------------------------------------------------
cat > "$ETC_OPENBOX/autostart" <<'EOF'
# Alien Openbox autostart
if command -v picom >/dev/null 2>&1; then
    picom -b --config /dev/null &
fi
EOF
chmod +x "$ETC_OPENBOX/autostart"
cp -a "$ETC_OPENBOX/autostart" "$SKEL_OPENBOX/autostart"

cat > "$ETC_OPENBOX/rc.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://openbox.org/3.4/rc file:///usr/share/openbox/rc.xsd">
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>${FONT_UI}</name>
      <size>9</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>${FONT_UI}</name>
      <size>9</size>
      <weight>normal</weight>
      <slant>normal</slant>
    </font>
    <font place="MenuHeader">
      <name>${FONT_UI}</name>
      <size>9</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="MenuItem">
      <name>${FONT_UI}</name>
      <size>9</size>
      <weight>normal</weight>
      <slant>normal</slant>
    </font>
    <font place="ActiveOnScreenDisplay">
      <name>${FONT_UI}</name>
      <size>9</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="InactiveOnScreenDisplay">
      <name>${FONT_UI}</name>
      <size>9</size>
      <weight>normal</weight>
      <slant>normal</slant>
    </font>
  </theme>
  <desktops>
    <number>4</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>Chill</name>
      <name>Social</name>
      <name>Chess</name>
      <name>Media</name>
    </names>
    <popupTime>875</popupTime>
  </desktops>
  <resize>
    <drawContent>yes</drawContent>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
    <popupFixedPosition>
      <x>10</x>
      <y>10</y>
    </popupFixedPosition>
  </resize>
  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    <keybind key="A-Tab">
      <action name="NextWindow">
        <finalactions>
          <action name="Focus"/>
          <action name="Raise"/>
          <action name="Unshade"/>
        </finalactions>
      </action>
    </keybind>
    <keybind key="W-d">
      <action name="ToggleShowDesktop"/>
    </keybind>
  </keyboard>
  <mouse>
    <dragThreshold>8</dragThreshold>
    <doubleClickTime>400</doubleClickTime>
    <screenEdgeWarpTime>400</screenEdgeWarpTime>
    <screenEdgeWarpMouse>false</screenEdgeWarpMouse>
    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="Unshade"/>
      </mousebind>
      <mousebind button="A-Right" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Left" action="DoubleClick">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>
    <context name="Close">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="Unshade"/>
      </mousebind>
      <mousebind button="Left" action="Click">
        <action name="Close"/>
      </mousebind>
    </context>
    <context name="Maximize">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="Unshade"/>
      </mousebind>
      <mousebind button="Left" action="Click">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>
    <context name="Iconify">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="Unshade"/>
      </mousebind>
      <mousebind button="Left" action="Click">
        <action name="Iconify"/>
      </mousebind>
    </context>
  </mouse>
</openbox_config>
EOF
cp -a "$ETC_OPENBOX/rc.xml" "$SKEL_OPENBOX/rc.xml"

# -----------------------------------------------------------------------------
# I. System Utilities and Desktop Entries
# -----------------------------------------------------------------------------
DEST_BIN="$WORK/config/includes.chroot/usr/bin"
DEST_APPS="$WORK/config/includes.chroot/usr/share/applications"
mkdir -p "$DEST_BIN" "$DEST_APPS"

# 1) alien-launcher.desktop (launches lxqt-runner)
cat > "$DEST_APPS/alien-launcher.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Alien Launcher
GenericName=App Launcher & Search
Comment=Search and launch applications
Exec=lxqt-runner
Icon=alien-launcher
Categories=System;Utility;
StartupNotify=false
Actions=AppCenter;

[Desktop Action AppCenter]
Name=App Center
Exec=alien-app-center
EOF

# 2) alien-performance-mode
cat > "$DEST_BIN/alien-performance-mode" <<'EOF'
#!/usr/bin/env bash
# Alien OS Performance Mode toggle (compositor on/off)
set -euo pipefail

MODE="${1:-toggle}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alien"
mkdir -p "$CONFIG_DIR"
STATE_FILE="$CONFIG_DIR/performance-mode"

current_state="off"
[ -f "$STATE_FILE" ] && current_state="$(cat "$STATE_FILE")"

if [ "$MODE" = "toggle" ]; then
    if [ "$current_state" = "on" ]; then
        MODE="off"
    else
        MODE="on"
    fi
fi

if [ "$MODE" = "on" ]; then
    killall picom 2>/dev/null || true
    echo "on" > "$STATE_FILE"
    if [ -n "${DISPLAY:-}" ] && command -v zenity >/dev/null 2>&1; then
        zenity --notification --text="Performance Mode: ON (Compositor off)" 2>/dev/null || true
    fi
    echo "Performance Mode: ON"
else
    if command -v picom >/dev/null 2>&1; then
        killall picom 2>/dev/null || true
        picom -b --config /dev/null &
    fi
    echo "off" > "$STATE_FILE"
    if [ -n "${DISPLAY:-}" ] && command -v zenity >/dev/null 2>&1; then
        zenity --notification --text="Performance Mode: OFF (Effects restored)" 2>/dev/null || true
    fi
    echo "Performance Mode: OFF"
fi
EOF
chmod +x "$DEST_BIN/alien-performance-mode"

cat > "$DEST_APPS/alien-performance-mode.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Performance Mode
Comment=Toggle between High Performance and Rich Effects
Exec=alien-performance-mode toggle
Icon=preferences-system-power-management
Categories=Settings;DesktopSettings;System;
EOF

# 3) alien-about
cat > "$DEST_BIN/alien-about" <<'EOF'
#!/usr/bin/env bash
# About Alien OS
if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="About Alien OS" \
      --window-icon="/usr/share/icons/hicolor/64x64/apps/alien-launcher.png" \
      --text="<b>Alien OS Lite Edition 0.1</b>\n<i>Your world, your way.</i>\n\n<b>Base:</b> Debian GNU/Linux 13 (Trixie)\n<b>Desktop:</b> LXQt 2.1 & Openbox\n\n<b>Credits & Courtesy:</b>\nAlien OS is proudly built upon Debian and the LXQt Desktop Project.\nSpecial thanks to the Debian, LXQt, and Openbox communities." \
      --width=420 --ok-label="Close" 2>/dev/null || true
else
    echo "Alien OS Lite Edition 0.1 — Your world, your way."
    echo "Built on Debian GNU/Linux and LXQt Desktop."
fi
EOF
chmod +x "$DEST_BIN/alien-about"

cat > "$DEST_APPS/alien-about.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=About Alien
GenericName=About Alien OS
Comment=Learn about Alien OS Lite Edition
Exec=alien-about
Icon=alien-launcher
Categories=Help;Settings;DesktopSettings;Qt;LXQt;
EOF

# 5) Retitle and re-icon Calamares "Install Debian" -> "Install Alien Lite"
cat > "$DEST_APPS/calamares-install-debian.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Alien Lite
GenericName=Calamares Installer
Exec=calamares-install-debian
Comment=Install Alien Lite to your computer
Keywords=calamares;system;install;alien;installer
Icon=alien-launcher
Terminal=false
Categories=Qt;System;
StartupWMClass=calamares
StartupNotify=True
EOF

# Preseed Calamares icon on Desktop
SKEL_DESKTOP="$WORK/config/includes.chroot/etc/skel/Desktop"
mkdir -p "$SKEL_DESKTOP"
cp -a "$DEST_APPS/calamares-install-debian.desktop" "$SKEL_DESKTOP/calamares-install-debian.desktop"
chmod +x "$SKEL_DESKTOP/calamares-install-debian.desktop"

# Patch add-calamares-desktop-icon to write "Install Alien Lite"
cat > "$DEST_BIN/add-calamares-desktop-icon" <<'EOF'
#!/bin/sh
DESKTOP=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
mkdir -p "$DESKTOP"
cp /usr/share/applications/calamares-install-debian.desktop "$DESKTOP/calamares-install-debian.desktop"
chmod +x "$DESKTOP/calamares-install-debian.desktop"
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ] && command -v gio >/dev/null 2>&1; then
    gio set --type=string "$DESKTOP/calamares-install-debian.desktop" metadata::trusted true 2>/dev/null || true
fi
EOF
chmod +x "$DEST_BIN/add-calamares-desktop-icon"

# -----------------------------------------------------------------------------
# J. Live user home preseed hook (/lib/live/config/9998-alien-user-skel)
# -----------------------------------------------------------------------------
DEST_LIVE_HOOKS="$WORK/config/includes.chroot/lib/live/config"
mkdir -p "$DEST_LIVE_HOOKS"
cat > "$DEST_LIVE_HOOKS/9998-alien-user-skel" <<'EOF'
#!/bin/sh
# 9998-alien-user-skel - Ensure live user receives all skel configs
for u in alien user $(ls /home 2>/dev/null); do
    if [ -d "/home/$u" ]; then
        mkdir -p "/home/$u/.config"
        cp -a /etc/skel/.config/* "/home/$u/.config/" 2>/dev/null || true
        if [ -d /etc/skel/Desktop ]; then
            mkdir -p "/home/$u/Desktop"
            cp -a /etc/skel/Desktop/* "/home/$u/Desktop/" 2>/dev/null || true
        fi
        chown -R "$u:$u" "/home/$u"
    fi
done
EOF
chmod +x "$DEST_LIVE_HOOKS/9998-alien-user-skel"

# -----------------------------------------------------------------------------
# K. Build hooks (chroot):
#    1) Clean stale ~/.config/lxqt and stale files
#    2) Remove xfwm4 and xfwm4-theme-breeze
#    3) Replace helix graphics with Alien logo2
#    4) Compile schemas, dconf update, icon caches
# -----------------------------------------------------------------------------
DEST_NORMAL_HOOKS="$WORK/config/hooks/normal"
mkdir -p "$DEST_NORMAL_HOOKS"

cat > "$DEST_NORMAL_HOOKS/0010-clean-stale-configs.hook.chroot" <<'EOF'
#!/bin/sh
set -e
rm -rf /root/.config/lxqt /home/*/.config/lxqt
rm -rf /root/.config/pcmanfm-qt /home/*/.config/pcmanfm-qt
EOF
chmod +x "$DEST_NORMAL_HOOKS/0010-clean-stale-configs.hook.chroot"

cat > "$DEST_NORMAL_HOOKS/0020-remove-unwanted-wms.hook.chroot" <<'EOF'
#!/bin/sh
set -e
dpkg -P xfwm4 xfwm4-theme-breeze 2>/dev/null || true
apt-get autoremove -y --purge 2>/dev/null || true
rm -f /usr/bin/xfwm4
EOF
chmod +x "$DEST_NORMAL_HOOKS/0020-remove-unwanted-wms.hook.chroot"

cat > "$DEST_NORMAL_HOOKS/0030-lxqt-alien-theme.hook.chroot" <<EOF
#!/bin/sh
set -e

# Create Alien LXQt theme from dark theme
if [ -d /usr/share/lxqt/themes/dark ]; then
    mkdir -p /usr/share/lxqt/themes/alien
    cp -a /usr/share/lxqt/themes/dark/* /usr/share/lxqt/themes/alien/
    if [ -f /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg ]; then
        cp /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg /usr/share/lxqt/themes/alien/mainmenu.svg
        cp /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg /usr/share/lxqt/themes/debian/mainmenu.svg 2>/dev/null || true
    fi
    cat > /usr/share/lxqt/themes/alien/wallpaper.cfg <<WPEOF
[Wallpaper]
File=/usr/share/backgrounds/alien-bg1.png
Mode=stretch
WPEOF
    ln -sf /usr/share/backgrounds/alien-bg1.png /usr/share/lxqt/themes/debian/wallpaper.svg 2>/dev/null || true
    ln -sf /usr/share/backgrounds/alien-bg1.png /usr/share/lxqt/themes/debian/wallpaper.png 2>/dev/null || true
fi

# Replace all LXQt hummingbird helix graphics with Alien logo2
if [ -d /usr/share/lxqt/graphics ]; then
    for f in /usr/share/lxqt/graphics/helix*; do
        [ -e "\$f" ] || continue
        case "\$f" in
            *.svg)
                if [ -f /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg ]; then
                    cp /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg "\$f"
                fi
                ;;
            *.png)
                if [ -f /usr/share/icons/hicolor/256x256/apps/alien-launcher.png ]; then
                    cp /usr/share/icons/hicolor/256x256/apps/alien-launcher.png "\$f"
                fi
                ;;
        esac
    done
fi

# Overwrite Papirus start-here and lxqt icons with Alien launcher
for d in /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark; do
    if [ -d "\$d" ]; then
        find "\$d" -name "start-here*.svg" -o -name "lxqt*.svg" -o -name "desktop-environment-lxqt.svg" | while read -r iconfile; do
            case "\$(basename "\$iconfile")" in
                start-here*|lxqt.svg|lxqt-about.svg|desktop-environment-lxqt.svg)
                    if [ -f /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg ]; then
                        cp /usr/share/icons/hicolor/scalable/apps/alien-launcher.svg "\$iconfile"
                    fi
                    ;;
            esac
        done
    fi
done

# Dconf and Gsettings compile
if command -v dconf >/dev/null 2>&1; then
    dconf update || true
fi
if command -v glib-compile-schemas >/dev/null 2>&1; then
    glib-compile-schemas /usr/share/glib-2.0/schemas || true
fi

# Icon cache updates
for theme in Alien Papirus Papirus-Dark hicolor; do
    if [ -d "/usr/share/icons/\$theme" ] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "/usr/share/icons/\$theme" 2>/dev/null || true
    fi
done
EOF
chmod +x "$DEST_NORMAL_HOOKS/0030-lxqt-alien-theme.hook.chroot"

echo "  - Preseeded LXQt, Openbox, and Alien identity for Alien Lite"
