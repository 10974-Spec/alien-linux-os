#!/usr/bin/env bash
# tests/qemu-gate.sh — Wrapper for automated QEMU gate
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/tests/qemu-gate.py" "$@"
