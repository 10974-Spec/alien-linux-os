#!/usr/bin/env bash
# Alien OS Package Diet
set -euo pipefail

DEST="$WORK/config/hooks/normal/9900-package-diet.hook.chroot"
mkdir -p "$(dirname "$DEST")"

cat > "$DEST" <<'EOF'
#!/bin/sh
set -e
echo ">>> Running package diet..."

# Remove -dev, -dbg, -doc packages
echo "Removing development, debug, and documentation packages..."
dpkg -l | grep -E -- '-(dev|dbg|doc)(\s|$)' | awk '{print $2}' | xargs -r apt-get remove -y --purge

# Clean APT caches but keep AppStream
echo "Cleaning APT caches..."
apt-get clean
find /var/lib/apt/lists -type f -not -name '*appstream*' -delete

# Remove locales (keeping English)
echo "Cleaning locales..."
if command -v locale-gen >/dev/null; then
    sed -i -e '/^[^#]/s/^/#/' -e '/en_US.UTF-8/s/^#//' /etc/locale.gen
    locale-gen
fi
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} +

# Drop Python pycache
echo "Dropping Python bytecode..."
find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Strip man pages
echo "Stripping man pages..."
rm -rf /usr/share/man/*

echo ">>> Package diet complete."
EOF
chmod +x "$DEST"
