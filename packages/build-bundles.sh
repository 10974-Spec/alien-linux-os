#!/usr/bin/env bash
# Build metapackages for Alien OS Add-Ons
set -euo pipefail

BUNDLES="office creative developer media-server android"

for b in $BUNDLES; do
    DIR="alien-bundle-$b"
    mkdir -p "$DIR/DEBIAN"
    
    cat > "$DIR/DEBIAN/control" <<EOF
Package: alien-bundle-$b
Version: 1.0
Section: metapackages
Priority: optional
Architecture: all
Maintainer: Alien OS Team <team@alienos.local>
Description: Alien OS $b bundle
 This is a metapackage for the $b add-on.
EOF
    
    if [ "$b" = "office" ]; then
        echo "Depends: libreoffice, hunspell-en-us" >> "$DIR/DEBIAN/control"
    elif [ "$b" = "creative" ]; then
        echo "Depends: gimp, inkscape, kdenlive" >> "$DIR/DEBIAN/control"
    elif [ "$b" = "developer" ]; then
        echo "Depends: git, build-essential, podman" >> "$DIR/DEBIAN/control"
    elif [ "$b" = "media-server" ]; then
        echo "Depends: jellyfin, navidrome" >> "$DIR/DEBIAN/control"
    elif [ "$b" = "android" ]; then
        echo "Depends: waydroid" >> "$DIR/DEBIAN/control"
    fi
    
    dpkg-deb --build "$DIR" >/dev/null
    echo "Built $DIR.deb"
done
