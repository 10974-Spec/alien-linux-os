#!/usr/bin/env bash
# Alien — one-command ISO build.
# Usage:   ./build/build.sh <full|lite> [--fresh]
#          --fresh    (wipe cache and build from scratch)
# Result:  out/alien-<edition>-<version>-amd64.iso  +  .sha256  +  build.log
#
# Everything runs inside a throw-away Debian container, so your own
# system is never modified. Uses Podman if installed, otherwise Docker.
set -euo pipefail

EDITION="${1:-}"
if [ "$EDITION" != "full" ] && [ "$EDITION" != "lite" ]; then
  echo "Usage: $0 <full|lite> [--fresh]"
  exit 1
fi
shift

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="alien-builder:trixie"
CACHE_VOL="alien-build-cache"

# Pick container engine
if command -v podman >/dev/null; then
  ENGINE=(sudo podman)          # live-build needs a root (privileged) container
elif command -v docker >/dev/null; then
  ENGINE=(docker)
else
  echo "ERROR: install Podman or Docker first (see docs/01-setup-build-environment.md)"; exit 1
fi
echo ">>> Using container engine: ${ENGINE[*]}"

FRESH=0; [ "${1:-}" = "--fresh" ] && FRESH=1
if [ "$FRESH" = 1 ]; then
  echo ">>> --fresh: removing download cache"
  "${ENGINE[@]}" volume rm -f "$CACHE_VOL" >/dev/null 2>&1 || true
fi

echo ">>> Preparing the Debian build container (first time takes a few minutes)"
"${ENGINE[@]}" build --network host -t "$IMAGE" -f "$ROOT/build/Containerfile" "$ROOT/build"

mkdir -p "$ROOT/out"
echo ">>> Building the ISO (first build: 30–90 min depending on your internet)"
"${ENGINE[@]}" run --rm --privileged --network host \
  -v "$ROOT":/alien \
  -v "$CACHE_VOL":/work \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -e ALIEN_EDITION="$EDITION" \
  "$IMAGE" bash /alien/build/inside-container.sh

echo
echo ">>> Done. Your ISO is in: $ROOT/out/"
ls -lh "$ROOT/out/"*.iso 2>/dev/null || true
