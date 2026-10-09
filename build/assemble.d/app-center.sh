#!/usr/bin/env bash
# Alien — Preseed Alien App Center (Pop Shop style store, Add-on bundles)
set -euo pipefail

DEST_LIB="$WORK/config/includes.chroot/usr/lib/alien-app-center"
DEST_BIN="$WORK/config/includes.chroot/usr/bin"
DEST_APPS="$WORK/config/includes.chroot/usr/share/applications"

mkdir -p "$DEST_LIB" "$DEST_BIN" "$DEST_APPS"

# 1. Install Alien App Center files
cp -a "$SRC/app-center/app_center.py" "$DEST_LIB/"
cp -a "$SRC/app-center/alien-picks.yaml" "$DEST_LIB/"
cp -a "$SRC/app-center/enable-flathub.sh" "$DEST_LIB/"
cp -a "$SRC/app-center/bundles" "$DEST_LIB/"
chmod +x "$DEST_LIB/app_center.py" "$DEST_LIB/enable-flathub.sh" "$DEST_LIB/bundles/"*.sh

# 2. Main binary launcher (/usr/bin/alien-app-center)
cat > "$DEST_BIN/alien-app-center" <<'EOF'
#!/bin/sh
exec python3 /usr/lib/alien-app-center/app_center.py "$@"
EOF
chmod +x "$DEST_BIN/alien-app-center"

# 3. Add-ons backward compatibility wrapper (/usr/bin/alien-add-ons)
cat > "$DEST_BIN/alien-add-ons" <<'EOF'
#!/bin/sh
# Compatibility wrapper: opens Alien App Center on Bundles page
exec alien-app-center --tab bundles "$@"
EOF
chmod +x "$DEST_BIN/alien-add-ons"

# 4. Desktop Entry
cp "$SRC/app-center/alien-app-center.desktop" "$DEST_APPS/alien-app-center.desktop"
chmod 644 "$DEST_APPS/alien-app-center.desktop"

echo "  - Preseeded Alien App Center and Add-On Bundles"
