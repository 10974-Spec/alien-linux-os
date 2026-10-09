#!/usr/bin/env bash
# Alien — Boot Menu & Plymouth Branding
set -euo pipefail

# 1. Plymouth Theme (chroot)
DEST_PLYMOUTH="$WORK/config/includes.chroot/usr/share/plymouth/themes/alien"
mkdir -p "$DEST_PLYMOUTH"

# Copy logo
cp "$SRC/branding/generated/plymouth/logo.png" "$DEST_PLYMOUTH/"

# Create Plymouth theme file
cat > "$DEST_PLYMOUTH/alien.plymouth" <<EOF
[Plymouth Theme]
Name=Alien
Description=A theme that features a centered logo and a spinner.
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/alien
ScriptFile=/usr/share/plymouth/themes/alien/alien.script
EOF

# Create Plymouth script file (simple centered logo with pulse/fade effect)
cat > "$DEST_PLYMOUTH/alien.script" <<EOF
Window.SetBackgroundTopColor(0.1, 0.1, 0.15);
Window.SetBackgroundBottomColor(0.1, 0.1, 0.15);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

progress = 0;
fun refresh_callback() {
    progress++;
    # Simple opacity pulse
    opacity = 0.5 + (Math.Sin(progress / 20.0) * 0.5);
    logo.sprite.SetOpacity(opacity);
}
Plymouth.SetRefreshFunction(refresh_callback);
EOF

# Set plymouth default theme (overriding boot-login.sh if any)
mkdir -p "$WORK/config/includes.chroot/etc/plymouth"
cat > "$WORK/config/includes.chroot/etc/plymouth/plymouthd.conf" <<EOF
[Daemon]
Theme=alien
ShowDelay=0
EOF

# Rebuild initramfs hook so Plymouth theme is included in the ISO
mkdir -p "$WORK/config/hooks/normal"
cat > "$WORK/config/hooks/normal/0050-plymouth-update.hook.chroot" <<EOF
#!/bin/sh
set -e
# Ensure plymouth theme is updated in initramfs
if command -v plymouth-set-default-theme >/dev/null; then
    plymouth-set-default-theme -R alien
fi
EOF
chmod +x "$WORK/config/hooks/normal/0050-plymouth-update.hook.chroot"


# 2. Boot Menu (binary)
# We place the background images into includes.binary so they get packaged,
# and use a binary hook to edit the grub/syslinux configs after live-build generates them.

mkdir -p "$WORK/config/includes.binary/isolinux"
mkdir -p "$WORK/config/includes.binary/boot/grub"

cp "$SRC/branding/generated/backgrounds/bg-bootmenu-1024x768.png" "$WORK/config/includes.binary/isolinux/splash.png"
cp "$SRC/branding/generated/backgrounds/bg-bootmenu-1920x1080.png" "$WORK/config/includes.binary/boot/grub/splash.png"

# Binary hook to patch menus
cat > "$WORK/config/hooks/normal/9900-boot-menu-branding.hook.binary" <<'EOF'
#!/bin/sh
set -e

EDITION_CAP="$(echo "$ALIEN_EDITION" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
OS_TITLE="@ALIEN_NAME@ $EDITION_CAP"

# Patch ISOLINUX (syslinux)
if [ -d binary/isolinux ]; then
    # Menu colors
    cat > binary/isolinux/menu.cfg <<MENU_EOF
menu hshift 0
menu width 82
menu title Boot Menu
menu background splash.png
menu color title    * #ffffffff *
menu color border   * #00000000 #00000000 none
menu color sel      * #ffffffff @ALIEN_ACCENT@ *
menu color unsel    * #ffffffff #00000000 none
menu color timeout_msg * #ffffffff #00000000 none
menu color timeout  * #ffffffff #00000000 none
MENU_EOF
    # Append actual entries
    grep -v "menu background" binary/isolinux/live.cfg >> binary/isolinux/menu.cfg || true

    # Replace labels
    sed -i "s|Live system|$OS_TITLE|g" binary/isolinux/menu.cfg binary/isolinux/live.cfg binary/isolinux/install.cfg 2>/dev/null || true
    sed -i "s|Live ($OS_TITLE)|$OS_TITLE Live|g" binary/isolinux/*.cfg 2>/dev/null || true
fi

# Patch GRUB
if [ -f binary/boot/grub/grub.cfg ]; then
    # Insert theme settings before menuentries
    sed -i '/menuentry /,$!d' binary/boot/grub/grub.cfg

    cat > binary/boot/grub/grub.cfg.new <<GRUB_EOF
set default=0
set timeout=5
source /boot/grub/theme.cfg
background_image /boot/grub/splash.png
set color_normal=white/black
set color_highlight=white/blue
GRUB_EOF
    cat binary/boot/grub/grub.cfg >> binary/boot/grub/grub.cfg.new
    mv binary/boot/grub/grub.cfg.new binary/boot/grub/grub.cfg

    # Replace labels
    sed -i "s|Live system|$OS_TITLE|g" binary/boot/grub/grub.cfg 2>/dev/null || true
    sed -i "s|Live ($OS_TITLE)|$OS_TITLE Live|g" binary/boot/grub/grub.cfg 2>/dev/null || true
fi
EOF
chmod +x "$WORK/config/hooks/normal/9900-boot-menu-branding.hook.binary"

echo "  - Configured Plymouth theme 'alien' and Boot Menu branding"
