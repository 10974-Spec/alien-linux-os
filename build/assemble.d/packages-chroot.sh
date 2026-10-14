#!/usr/bin/env bash
# Alien — copy built .deb packages to config/packages.chroot for live-build installation
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

DEST="$WORK/config/packages.chroot"
mkdir -p "$DEST"

echo "Copying Alien deb packages to config/packages.chroot/..."
COUNT=0
for deb in "$SRC"/packages/*.deb "$SRC"/layers/shared/packages.chroot/*.deb; do
    [ -f "$deb" ] || continue
    fname="$(basename "$deb")"
    
    # alien-bundle-* packages are on-demand bundles for alien-store, not for base install
    if [[ "$fname" =~ ^alien-bundle- ]]; then
        continue
    fi
    
    cp -a "$deb" "$DEST/$fname"
    COUNT=$((COUNT + 1))
    
    # Wire alien-wallpapers and alien-wallpaper-migrate with _all.deb suffix for live-build
    if [[ "$fname" =~ ^alien-wallpaper.*\.deb$ ]] && [[ ! "$fname" =~ _all\.deb$ ]]; then
        ln -sf "$fname" "$DEST/${fname%.deb}_all.deb"
    fi
done

echo "  - Wired $COUNT deb package(s) into packages.chroot (total: $(ls -1 "$DEST"/*.deb 2>/dev/null | wc -l))"

