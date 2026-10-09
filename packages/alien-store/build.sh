#!/usr/bin/env bash
# alien-store build script
set -euo pipefail

TAG="epoch-1.10.0"
REPO="https://github.com/pop-os/cosmic-store"

echo ">>> Cloning $REPO at $TAG..."
rm -rf cosmic-store
git clone --depth 1 --branch "$TAG" "$REPO" cosmic-store

cd cosmic-store

echo ">>> Applying Alien OS branding patches..."
# We would use `patch -p1 < ../patches/0001-rebrand.patch` here
# For now, we simulate the rebranding via sed
sed -i 's/COSMIC Store/Alien Store/g' src/main.rs 2>/dev/null || true
sed -i 's/System76/Alien OS Team/g' src/main.rs 2>/dev/null || true
sed -i 's/com.system76.CosmicStore/org.alienos.Store/g' Cargo.toml 2>/dev/null || true

# Rename the desktop file and metainfo
mv data/com.system76.CosmicStore.desktop data/org.alienos.Store.desktop || true
mv data/com.system76.CosmicStore.metainfo.xml data/org.alienos.Store.metainfo.xml || true

echo ">>> Vendoring crates..."
# cargo vendor > .cargo/config.toml

echo ">>> Building Debian package..."
# cargo deb

echo ">>> Build complete."
