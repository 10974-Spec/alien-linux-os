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
cat > "$WORK/config/hooks/normal/0050-plymouth-update.hook.chroot" <<'EOF'
#!/bin/sh
set -e
# Ensure plymouth theme is set and baked into initramfs
if command -v plymouth-set-default-theme >/dev/null; then
    plymouth-set-default-theme -R alien || true
fi
if command -v update-initramfs >/dev/null; then
    update-initramfs -u -k all || true
fi
EOF
chmod +x "$WORK/config/hooks/normal/0050-plymouth-update.hook.chroot"


# 2. Graphical GRUB Theme & Boot Menu Architecture (Binary and Chroot)
DEST_GRUB_BIN="$WORK/config/includes.binary/boot/grub"
DEST_GRUB_CHROOT="$WORK/config/includes.chroot/boot/grub"
DEST_THEME_BIN="$DEST_GRUB_BIN/themes/alien"
DEST_THEME_CHROOT="$DEST_GRUB_CHROOT/themes/alien"

mkdir -p "$DEST_THEME_BIN" "$DEST_THEME_CHROOT"

if [ -d "$SRC/branding/generated/grub" ]; then
	cp -a "$SRC/branding/generated/grub/"* "$DEST_THEME_BIN/"
	cp -a "$SRC/branding/generated/grub/"* "$DEST_THEME_CHROOT/"
fi

# Installed system GRUB defaults (/etc/default/grub.d/50_alien.cfg)
DEST_GRUB_CONF="$WORK/config/includes.chroot/etc/default/grub.d"
mkdir -p "$DEST_GRUB_CONF"
cat > "$DEST_GRUB_CONF/50_alien.cfg" <<'EOF'
# Alien OS Architecture & GRUB Configuration
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=false
GRUB_TIMEOUT=1
GRUB_TIMEOUT_STYLE=hidden
GRUB_RECORDFAIL_TIMEOUT=5
GRUB_THEME=/boot/grub/themes/alien/theme.txt
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_OS_PROBER=false
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0 panic=10"
EOF

# Unbrickable Boot Assessment: Attempt counter in GRUB
DEST_GRUB_D="$WORK/config/includes.chroot/etc/grub.d"
mkdir -p "$DEST_GRUB_D"

cat > "$DEST_GRUB_D/01_alien_boot_counter" <<'EOF'
#!/bin/sh
# Alien OS — Boot assessment & automatic fallback counter
exec tail -n +3 $0
# Locate EFI System Partition if present
if [ -z "$esp" ]; then
  search --no-floppy --file --set=esp /EFI/alien/grubenv
  if [ -z "$esp" ]; then
    search --no-floppy --file --set=esp /EFI/debian/grubx64.efi
  fi
  if [ -z "$esp" ]; then
    search --no-floppy --file --set=esp /EFI/BOOT/BOOTX64.EFI
  fi
fi

# Load grub environment from ESP or standard location
if [ -n "$esp" ]; then
  load_env -f ($esp)/EFI/alien/grubenv
elif [ -s /boot/grub/grubenv ]; then
  load_env
fi

# Initialize counter if not set
if [ -z "${alien_boot_tries}" ]; then
  set alien_boot_tries=3
fi

if [ "${alien_boot_success}" = "1" ]; then
  set alien_boot_tries=3
  set alien_boot_success=0
  if [ -n "$esp" ]; then
    save_env -f ($esp)/EFI/alien/grubenv alien_boot_tries alien_boot_success
  elif [ "${root}" != "btrfs" ]; then
    save_env alien_boot_tries alien_boot_success
  fi
else
  # Decrement tries counter
  if [ "${alien_boot_tries}" = "3" ]; then
    set alien_boot_tries=2
  elif [ "${alien_boot_tries}" = "2" ]; then
    set alien_boot_tries=1
  elif [ "${alien_boot_tries}" = "1" ]; then
    set alien_boot_tries=0
    # Fallback to recovery / previous kernel or snapshot
    set default="Advanced options for Alien OS>1"
    set timeout_style=menu
    set timeout=10
  fi
  if [ -n "$esp" ]; then
    save_env -f ($esp)/EFI/alien/grubenv alien_boot_tries
  elif [ "${root}" != "btrfs" ]; then
    save_env alien_boot_tries
  fi
fi
EOF
chmod +x "$DEST_GRUB_D/01_alien_boot_counter"

# Systemd service to mark boot as healthy once desktop session is ready
DEST_SYSTEMD="$WORK/config/includes.chroot/etc/systemd/system"
mkdir -p "$DEST_SYSTEMD"
cat > "$DEST_SYSTEMD/alien-boot-good.service" <<'EOF'
[Unit]
Description=Alien OS Mark Boot Healthy
After=graphical.target systemd-user-sessions.service
Wants=graphical.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/alien-boot-mark-good

[Install]
WantedBy=graphical.target
EOF

DEST_BIN="$WORK/config/includes.chroot/usr/bin"
mkdir -p "$DEST_BIN"
cat > "$DEST_BIN/alien-boot-mark-good" <<'EOF'
#!/bin/sh
set -eu
# Check basic health: display manager active or graphical target reached
if systemctl is-active --quiet display-manager.service || systemctl is-active --quiet lightdm.service || systemctl is-active --quiet sddm.service || systemctl is-active --quiet graphical.target; then
  if [ -d /boot/efi ]; then
    mkdir -p /boot/efi/EFI/alien
    grub-editenv /boot/efi/EFI/alien/grubenv set alien_boot_tries=3 alien_boot_success=1 2>/dev/null || true
  elif [ -f /boot/grub/grubenv ]; then
    grub-editenv /boot/grub/grubenv set alien_boot_tries=3 alien_boot_success=1 2>/dev/null || true
  fi
fi
EOF
chmod +x "$DEST_BIN/alien-boot-mark-good"

mkdir -p "$DEST_SYSTEMD/graphical.target.wants"
ln -sf /etc/systemd/system/alien-boot-good.service "$DEST_SYSTEMD/graphical.target.wants/alien-boot-good.service"

# Binary hook to install unified Live ISO GRUB menu (BIOS & UEFI)
cat > "$WORK/config/hooks/normal/9900-boot-menu-branding.hook.binary" <<'EOF'
#!/bin/sh
set -e

if [ -d binary ]; then
  ROOT_BIN="binary"
else
  ROOT_BIN="."
fi

EDITION_CAP="$(echo "$ALIEN_EDITION" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
OS_TITLE="@ALIEN_NAME@ $EDITION_CAP"

mkdir -p "$ROOT_BIN/boot/grub/themes/alien"
if [ -d /alien/branding/generated/grub ]; then
  cp -a /alien/branding/generated/grub/* "$ROOT_BIN/boot/grub/themes/alien/" 2>/dev/null || true
fi

# Ensure standard vmlinuz and initrd.img symlinks exist in binary/live
if [ -d "$ROOT_BIN/live" ]; then
  ( cd "$ROOT_BIN/live" && \
    for k in vmlinuz-*; do [ -f "$k" ] && ln -sf "$k" vmlinuz; break; done && \
    for i in initrd.img-*; do [ -f "$i" ] && ln -sf "$i" initrd.img; break; done ) || true
fi

# Generate unified GRUB configuration for Live ISO
cat > "$ROOT_BIN/boot/grub/grub.cfg" <<GRUB_EOF
set default=0
set timeout=1
set timeout_style=hidden

# Enable high-resolution graphics and keep for kernel
set gfxmode=auto
set gfxpayload=keep
insmod all_video
insmod gfxterm
insmod png
terminal_output gfxterm

# Load graphical theme
loadfont /boot/grub/themes/alien/dejavu-14.pf2
loadfont /boot/grub/themes/alien/dejavu-bold-14.pf2
set theme=/boot/grub/themes/alien/theme.txt

# Visible top-level is a single entry
menuentry "$OS_TITLE" --class alien --class gnu-linux --class os {
    linux /live/vmlinuz boot=live components quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0 console=tty0 console=ttyS0 locales=@ALIEN_LOCALE@ keyboard-layouts=@ALIEN_KEYMAP@ timezone=@ALIEN_TIMEZONE@ hostname=@ALIEN_HOSTNAME@ username=@ALIEN_LIVE_USER@
    initrd /live/initrd.img
}

# Everything else lives in a single "More options" submenu
submenu "More options" --class submenu {
    menuentry "$OS_TITLE (Automated Self-Test)" --class test --class os {
        linux /live/vmlinuz boot=live components quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0 alien.selftest=1 console=tty0 console=ttyS0 locales=@ALIEN_LOCALE@ keyboard-layouts=@ALIEN_KEYMAP@ timezone=@ALIEN_TIMEZONE@ hostname=@ALIEN_HOSTNAME@ username=@ALIEN_LIVE_USER@
        initrd /live/initrd.img
    }

    menuentry "$OS_TITLE (Copy to RAM)" --class alien --class ram --class os {
        linux /live/vmlinuz boot=live components quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0 alien.toram=auto console=tty0 console=ttyS0 locales=@ALIEN_LOCALE@ keyboard-layouts=@ALIEN_KEYMAP@ timezone=@ALIEN_TIMEZONE@ hostname=@ALIEN_HOSTNAME@ username=@ALIEN_LIVE_USER@
        initrd /live/initrd.img
    }

    menuentry "$OS_TITLE (Persistence)" --class alien --class disk --class os {
        linux /live/vmlinuz boot=live components quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0 persistence console=tty0 console=ttyS0 locales=@ALIEN_LOCALE@ keyboard-layouts=@ALIEN_KEYMAP@ timezone=@ALIEN_TIMEZONE@ hostname=@ALIEN_HOSTNAME@ username=@ALIEN_LIVE_USER@
        initrd /live/initrd.img
    }

    menuentry "$OS_TITLE (Safe Graphics / nomodeset)" --class recovery --class safe --class os {
        linux /live/vmlinuz boot=live components nomodeset console=tty0 console=ttyS0 locales=@ALIEN_LOCALE@ keyboard-layouts=@ALIEN_KEYMAP@ timezone=@ALIEN_TIMEZONE@ hostname=@ALIEN_HOSTNAME@ username=@ALIEN_LIVE_USER@
        initrd /live/initrd.img
    }

    menuentry "Install $OS_TITLE" --class calamares --class install --class os {
        linux /live/vmlinuz boot=live components quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0 alien.autoinstall=1 console=tty0 console=ttyS0 locales=@ALIEN_LOCALE@ keyboard-layouts=@ALIEN_KEYMAP@ timezone=@ALIEN_TIMEZONE@ hostname=@ALIEN_HOSTNAME@ username=@ALIEN_LIVE_USER@
        initrd /live/initrd.img
    }

    menuentry "Memory Diagnostic (memtest86+)" --class memtest {
        linux16 /live/memtest86+.bin 2>/dev/null || linux /live/memtest86+ 2>/dev/null || chainloader /boot/memtest.efi
    }

    if [ "\$grub_platform" = "efi" ]; then
        menuentry "UEFI Firmware Settings" --class uefi-firmware {
            fwsetup
        }
    fi

    menuentry "Reboot System" --class reboot {
        reboot
    }

    menuentry "Power Off" --class shutdown {
        halt
    }
}
GRUB_EOF

# Keep isolinux fallback for legacy BIOS media if present
if [ -d "$ROOT_BIN/isolinux" ]; then
    cat > "$ROOT_BIN/isolinux/menu.cfg" <<MENU_EOF
menu hshift 0
menu width 82
menu title Alien OS Boot Menu
menu background splash.png
menu color title    * #ffffffff *
menu color border   * #00000000 #00000000 none
menu color sel      * #ffffffff @ALIEN_ACCENT@ *
menu color unsel    * #ffffffff #00000000 none
menu color timeout  * #ffffffff #00000000 none
MENU_EOF
    grep -v "menu background" "$ROOT_BIN/isolinux/live.cfg" >> "$ROOT_BIN/isolinux/menu.cfg" 2>/dev/null || true
fi
EOF
chmod +x "$WORK/config/hooks/normal/9900-boot-menu-branding.hook.binary"

echo "  - Configured Plymouth theme 'alien' and unified GRUB Boot Architecture"

