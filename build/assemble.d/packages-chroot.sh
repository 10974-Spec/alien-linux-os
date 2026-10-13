#!/usr/bin/env bash
# Alien — copy built .deb packages to config/packages.chroot for live-build installation
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

DEST="$WORK/config/packages.chroot"
mkdir -p "$DEST"

echo "Copying Alien deb packages to config/packages.chroot/..."
COUNT=0
for deb in "$SRC"/packages/*.deb; do
    if [ -f "$deb" ]; then
        cp -a "$deb" "$DEST/"
        COUNT=$((COUNT + 1))
    fi
done

echo "  - Wired $COUNT deb package(s) into packages.chroot"
