#!/usr/bin/env bash
# Alien — runs INSIDE the build container (called by build/build.sh).
# Do not run this on your own computer.
set -euo pipefail

SRC=/alien
WORK=/work/lb
source "$SRC/alien.conf"
export ALIEN_EDITION_CAPITALIZED="$(echo "$ALIEN_EDITION" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

mkdir -p "$WORK"
cd "$WORK"

# 1. Clean the previous build but keep the download cache (cache/)
if [ -d .build ]; then lb clean || true; fi
rm -rf auto config alien.conf

# Ensure bootstrap cache has CA certificates for HTTPS repositories (like VS Code)
if [ -d cache/bootstrap ]; then
    mkdir -p cache/bootstrap/etc/ssl
    cp -a /etc/ssl/certs cache/bootstrap/etc/ssl/ 2>/dev/null || true
fi

# 2. Copy live-build shared config and then layer edition-specific config on top
cp -a "$SRC/build/auto" .
mkdir -p config
if [ -d "$SRC/layers/shared" ]; then
  cp -a "$SRC/layers/shared"/* config/
fi
if [ -d "$SRC/layers/$ALIEN_EDITION" ]; then
  cp -a "$SRC/layers/$ALIEN_EDITION"/* config/
fi
cp "$SRC/alien.conf" .

# 3. Assemble extra content (themes, branding, apps) into config/
#    Each script in build/assemble.d/ gets SRC and WORK as env vars.
if [ -d "$SRC/build/assemble.d" ]; then
  for s in "$SRC"/build/assemble.d/*.sh; do
    [ -e "$s" ] || continue
    echo ">>> assemble: $(basename "$s")"
    SRC="$SRC" WORK="$WORK" bash "$s"
  done
fi

# 4. Fill in @ALIEN_*@ placeholders from alien.conf (accent colour, name...)
mapfile -t files < <(grep -rlI '@ALIEN_[A-Z_]*@' config auto 2>/dev/null || true)
for f in "${files[@]}"; do
  for var in $(compgen -v ALIEN_); do
    val="${!var}"
    sed -i "s|@${var}@|${val//|/\\|}|g" "$f"
  done
done
echo ">>> filled placeholders in ${#files[@]} file(s)"

# 5. Configure and build
lb config
if [ "$ALIEN_EDITION" = "lite" ]; then
  # Overwrite specific options for the Lite edition
  lb config \
    --bootappend-live "boot=live components quiet splash locales=$ALIEN_LOCALE keyboard-layouts=$ALIEN_KEYMAP timezone=$ALIEN_TIMEZONE hostname=$ALIEN_HOSTNAME username=$ALIEN_LIVE_USER toram persistence console=ttyS0" \
    --chroot-squashfs-compression-type zstd
  export MKSQUASHFS_OPTIONS="-b 1M -comp zstd -Xcompression-level 19"
fi
set +e
lb build 2>&1 | tee "$SRC/out/build.log"
rc=${PIPESTATUS[0]}
set -e

# 6. Collect the result
iso=$(ls -t "$WORK"/*.iso 2>/dev/null | head -1 || true)
if [ "$rc" -ne 0 ] || [ -z "$iso" ]; then
  echo "!!! BUILD FAILED (exit $rc). See out/build.log"
  chown "$HOST_UID:$HOST_GID" "$SRC/out/build.log" || true
  exit 1
fi
DATE_STR=$(date +%Y%m%d)
name="${ALIEN_ID}-${ALIEN_EDITION}-${ALIEN_VERSION}-${DATE_STR}-amd64.iso"
mv -f "$iso" "$SRC/out/$name"
( cd "$SRC/out" && sha256sum "$name" > "$name.sha256" )
chown "$HOST_UID:$HOST_GID" "$SRC/out" "$SRC/out/$name" "$SRC/out/$name.sha256" "$SRC/out/build.log"
echo ">>> SUCCESS: out/$name"
