#!/usr/bin/env bash
# Install alien tools to the chroot
set -euo pipefail

DEST="$WORK/config/includes.chroot/usr/bin"
mkdir -p "$DEST"

for tool in "$SRC"/tools/alien-*/*; do
    if [ -f "$tool" ] && [ -x "$tool" ]; then
        cp -a "$tool" "$DEST/"
    fi
done

# Install alien-scripts (legacy)
if [ -d "$SRC/tools/alien-scripts" ]; then
    cp -a "$SRC"/tools/alien-scripts/* "$DEST/" 2>/dev/null || true
fi
