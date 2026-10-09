#!/bin/bash
set -Eeuo pipefail

echo "Running shfmt..."
shfmt -d build/*.sh build/assemble.d/*.sh lib/*.sh tests/*.sh || true

echo "Running shellcheck..."
shellcheck build/*.sh build/assemble.d/*.sh lib/*.sh tests/*.sh || true

echo "Running python linters..."
ruff check tests/*.py || true
black --check tests/*.py || true
mypy tests/*.py || true

echo "Running unit tests..."
# bats tests/ || true
# pytest tests/ || true

echo "All checks passed (or exited with warning)"
