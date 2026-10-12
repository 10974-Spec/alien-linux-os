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
if [ "$EDITION" = "clean" ]; then
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  IMAGE="alien-builder:trixie"
  CACHE_VOL="alien-build-cache"
  if [ -n "${CONTAINER_ENGINE:-}" ]; then
    ENGINE=($CONTAINER_ENGINE)
  elif docker info >/dev/null 2>&1; then
    ENGINE=(docker)
  elif command -v podman >/dev/null; then
    ENGINE=(sudo podman)
  else
    ENGINE=(docker)
  fi
  echo ">>> Removing download cache volume $CACHE_VOL..."
  "${ENGINE[@]}" volume rm -f "$CACHE_VOL" >/dev/null 2>&1 || true
  rm -f "$ROOT/.build_inputs_hash" "$ROOT/out/build.log"
  echo ">>> Clean completed."
  exit 0
fi

if [ "$EDITION" != "full" ] && [ "$EDITION" != "lite" ]; then
  echo "Usage: $0 <full|lite|clean> [--fresh]"
  exit 1
fi
shift

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="alien-builder:trixie"
CACHE_VOL="alien-build-cache"

# Pick container engine
if [ -n "${CONTAINER_ENGINE:-}" ]; then
  ENGINE=($CONTAINER_ENGINE)
elif docker info >/dev/null 2>&1; then
  ENGINE=(docker)
elif command -v podman >/dev/null; then
  ENGINE=(sudo podman)          # live-build needs a root (privileged) container
elif command -v docker >/dev/null; then
  ENGINE=(docker)
else
  echo "ERROR: install Podman or Docker first (see docs/01-setup-build-environment.md)"; exit 1
fi
echo ">>> Using container engine: ${ENGINE[*]}"

# Generate unique Build ID (date/time + git short hash)
DATE_STAMP="$(date +%Y%m%d-%H%M)"
GIT_HASH="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "dev")"
BUILD_ID="${DATE_STAMP}-${GIT_HASH}"
export ALIEN_BUILD_ID="$BUILD_ID"
echo ">>> Build ID: $BUILD_ID"

# Input change detection: if package lists, hooks, or packages changed, clean stale chroot cache
INPUTS_HASH=$( (
  find "$ROOT/layers" "$ROOT/packages" "$ROOT/build/assemble.d" -type f 2>/dev/null | sort | while read -r f; do
    sha256sum "$f" 2>/dev/null || true
  done
) | sha256sum | cut -d' ' -f1 )

FRESH=0; [ "${1:-}" = "--fresh" ] && FRESH=1
if [ "$FRESH" = 1 ]; then
  echo ">>> --fresh: removing download cache volume..."
  "${ENGINE[@]}" volume rm -f "$CACHE_VOL" >/dev/null 2>&1 || true
fi
echo "$INPUTS_HASH" > "$ROOT/.build_inputs_hash"

echo ">>> Preparing the Debian build container (first time takes a few minutes)"
"${ENGINE[@]}" build --network host -t "$IMAGE" -f "$ROOT/build/Containerfile" "$ROOT/build"

mkdir -p "$ROOT/out"
echo ">>> Building the ISO (Build ID: $BUILD_ID)"
"${ENGINE[@]}" run --rm --privileged --network host \
  -v "$ROOT":/alien \
  -v "$CACHE_VOL":/work \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -e ALIEN_EDITION="$EDITION" \
  -e ALIEN_BUILD_ID="$BUILD_ID" \
  "$IMAGE" bash /alien/build/inside-container.sh

echo
echo ">>> Done. Your ISO is in: $ROOT/out/"
ls -lh "$ROOT/out/"*.iso 2>/dev/null || true
