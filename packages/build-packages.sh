#!/usr/bin/env bash
# Build all Alien OS architecture and bundle deb packages
set -euo pipefail

cd "$(dirname "$0")"

for d in alien-*; do
    if [ -d "$d/DEBIAN" ]; then
        dpkg-deb --build "$d" >/dev/null
        echo "Built $d.deb"
    fi
done
