#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# tests/run-wallpaper-migrate-tests.sh
# Runs the wallpaper migration unit test scenarios inline (no bats required).
set -euo pipefail

MIGRATE_SCRIPT="$(dirname "$0")/../packages/alien-wallpaper-migrate/usr/bin/alien-wallpaper-migrate"
NEW_DEFAULT="/usr/share/backgrounds/alien/default.png"
PASS=0
FAIL=0

run_test() {
    local name="$1"
    local expected_wp="$2"
    local initial_wp="$3"
    local marker_before="$4"

    local fake
    fake="$(mktemp -d)"
    mkdir -p "${fake}/.config/pcmanfm-qt/lxqt" "${fake}/.config/alien"

    if [ -n "$initial_wp" ]; then
        cat > "${fake}/.config/pcmanfm-qt/lxqt/settings.conf" <<EOF
[Desktop]
Wallpaper=${initial_wp}
WallpaperMode=stretch
EOF
    fi

    [ "$marker_before" = "1" ] && touch "${fake}/.config/alien/wallpaper-migrate.v1"

    HOME="$fake" DISPLAY="" bash "$MIGRATE_SCRIPT" 2>/dev/null || true

    local actual
    actual=$(grep -E "^Wallpaper=" "${fake}/.config/pcmanfm-qt/lxqt/settings.conf" 2>/dev/null | cut -d= -f2- | tr -d ' \r\n') || true

    rm -rf "$fake"

    if [ "$actual" = "$expected_wp" ]; then
        echo "  [PASS] $name"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $name: expected='$expected_wp' actual='$actual'"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Wallpaper Migration Unit Tests ==="

run_test "old alien-bg1.png → migrated to new default" \
    "$NEW_DEFAULT" "/usr/share/backgrounds/alien-bg1.png" "0"

run_test "old panel_3_1.png → migrated to new default" \
    "$NEW_DEFAULT" "/usr/share/backgrounds/panel_3_1.png" "0"

run_test "custom wallpaper → untouched" \
    "/home/user/Pictures/custom.png" "/home/user/Pictures/custom.png" "0"

run_test "marker present → no-op (old default stays)" \
    "/usr/share/backgrounds/alien-bg1.png" "/usr/share/backgrounds/alien-bg1.png" "1"

# Fresh home marker test
fake="$(mktemp -d)"
mkdir -p "${fake}/.config/alien"
HOME="$fake" DISPLAY="" bash "$MIGRATE_SCRIPT" 2>/dev/null || true
if [ -f "${fake}/.config/alien/wallpaper-migrate.v1" ]; then
    echo "  [PASS] fresh home → marker written"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] fresh home → marker NOT written"
    FAIL=$((FAIL + 1))
fi
rm -rf "$fake"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    echo "MIGRATION TESTS FAILED"
    exit 1
fi
echo "ALL MIGRATION TESTS PASSED"
