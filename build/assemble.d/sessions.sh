#!/usr/bin/env bash
# Alien — Fix extra sessions and live auto-login
set -euo pipefail

DEST_HOOKS="$WORK/config/includes.chroot/lib/live/config"
mkdir -p "$DEST_HOOKS"

# Create a live-config script to enforce auto-login on live boot
cat > "$DEST_HOOKS/9999-alien-autologin" <<'EOF'
#!/bin/sh
# 9999-alien-autologin - Enforce live auto-login for Alien OS
# This runs only during the live boot.

if [ -d /etc/sddm.conf.d ]; then
  cat > /etc/sddm.conf.d/live-autologin.conf <<INL
[Autologin]
User=alien
Session=plasma
INL
fi

if [ -d /etc/lightdm/lightdm.conf.d ]; then
  cat > /etc/lightdm/lightdm.conf.d/live-autologin.conf <<INL
[Seat:*]
autologin-user=alien
autologin-session=lxqt
INL
fi
EOF
chmod +x "$DEST_HOOKS/9999-alien-autologin"

# Create a build hook to hide all sessions except our designated ones
DEST_NORMAL_HOOKS="$WORK/config/hooks/normal"
mkdir -p "$DEST_NORMAL_HOOKS"

cat > "$DEST_NORMAL_HOOKS/9900-fix-sessions.hook.chroot" <<'EOF'
#!/bin/sh
set -e

# Hide all sessions except plasma and lxqt
for s in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
  [ -f "$s" ] || continue
  case "$(basename "$s")" in
    plasma.desktop|lxqt.desktop) ;;
    *) echo "NoDisplay=true" >> "$s" ;;
  esac
done

# Ensure the default system session points to our desired session
if [ -e /usr/bin/startlxqt ]; then
  update-alternatives --set x-session-manager /usr/bin/startlxqt || true
fi
EOF
chmod +x "$DEST_NORMAL_HOOKS/9900-fix-sessions.hook.chroot"

echo "  - Configured session cleanup and live auto-login"
