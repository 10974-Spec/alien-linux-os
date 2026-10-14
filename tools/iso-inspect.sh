#!/usr/bin/env bash
# tools/iso-inspect.sh
# Inspects an Alien ISO (defaults to newest in out/) and reports presence/validity
# of required binaries, desktop files, icons, packages, panel defaults, and policies
# per Phase 8 of "Reset and Make it Real".

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO="${1:-}"

if [ -z "$ISO" ]; then
    ISO=$(ls -t "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)
fi

if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
    echo "ERROR: No ISO file found or specified." >&2
    exit 1
fi

echo "============================================================"
echo " Alien ISO Inspector (Reset and Make It Real)"
echo " Target ISO: $ISO"
echo " Timestamp:  $(date -r "$ISO" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
echo " Size:       $(du -h "$ISO" | cut -f1)"
echo "============================================================"

TMPDIR=$(mktemp -d /tmp/alien-iso-inspect-XXXXXX)
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# 1. Extract live image components from ISO
echo ">>> Extracting live image components from ISO..."
if command -v osirrox >/dev/null 2>&1; then
    osirrox -indev "$ISO" -extract live/filesystem.squashfs "$TMPDIR/filesystem.squashfs" >/dev/null 2>&1 || true
    osirrox -indev "$ISO" -extract live/filesystem.packages "$TMPDIR/filesystem.packages" >/dev/null 2>&1 || true
    osirrox -indev "$ISO" -extract boot/grub/grub.cfg "$TMPDIR/grub.cfg" >/dev/null 2>&1 || true
elif command -v xorriso >/dev/null 2>&1; then
    xorriso -osirrox on -indev "$ISO" -extract live/filesystem.squashfs "$TMPDIR/filesystem.squashfs" >/dev/null 2>&1 || true
    xorriso -osirrox on -indev "$ISO" -extract live/filesystem.packages "$TMPDIR/filesystem.packages" >/dev/null 2>&1 || true
    xorriso -osirrox on -indev "$ISO" -extract boot/grub/grub.cfg "$TMPDIR/grub.cfg" >/dev/null 2>&1 || true
fi

if [ ! -f "$TMPDIR/filesystem.squashfs" ]; then
    echo "ERROR: Failed to extract live/filesystem.squashfs from ISO" >&2
    exit 1
fi

# 2. Extract inspection targets from SquashFS
ROOTFS="$TMPDIR/rootfs"
mkdir -p "$ROOTFS"

echo ">>> Unpacking target files from SquashFS..."
unsquashfs -d "$ROOTFS" -f "$TMPDIR/filesystem.squashfs" \
    "usr/bin" \
    "usr/local/bin" \
    "usr/share/applications" \
    "usr/share/icons" \
    "usr/share/plymouth" \
    "var/lib/dpkg/status" \
    "etc/skel" \
    "etc/xdg" \
    "etc/brave" \
    "etc/alien-build" \
    "etc/plymouth" \
    "usr/share/backgrounds" \
    >/dev/null 2>&1 || true

FAIL_COUNT=0

record_result() {
    local status="$1"
    local category="$2"
    local item="$3"
    local detail="${4:-}"
    if [ "$status" = "OK" ]; then
        printf "  [PASS] %-15s %-30s %s\n" "[$category]" "$item" "$detail"
    else
        printf "  [FAIL] %-15s %-30s %s\n" "[$category]" "$item" "$detail"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo
echo "--- 1. Required Established Binaries ---"
REQUIRED_BINARIES=(
    "brave-browser"
    "vlc"
    "lximage-qt"
    "ghostwriter"
    "featherpad"
    "alien-store"
    "alien-panel-migrate"
)

for bin in "${REQUIRED_BINARIES[@]}"; do
    bin_path="$ROOTFS/usr/bin/$bin"
    [ ! -f "$bin_path" ] && bin_path="$ROOTFS/usr/local/bin/$bin"
    if [ -f "$bin_path" ] && [ -x "$bin_path" ]; then
        record_result "OK" "BINARY" "$bin" "found: $bin_path"
    elif [ -f "$bin_path" ]; then
        record_result "FAIL" "BINARY" "$bin" "not executable: $bin_path"
    else
        record_result "FAIL" "BINARY" "$bin" "MISSING"
    fi
done

echo
echo "--- 2. Retired Skeleton Apps & Social Web Apps Purge Check ---"
RETIRED_ITEMS=(
    "alien-webapp"
    "alien-player"
    "alien-viewer"
    "alien-notes"
    "alien-enable-drm"
)

for ret in "${RETIRED_ITEMS[@]}"; do
    if [ -f "$ROOTFS/usr/bin/$ret" ]; then
        record_result "FAIL" "RETIRED-BIN" "$ret" "still present in /usr/bin/$ret"
    else
        record_result "OK" "RETIRED-BIN" "$ret" "properly purged"
    fi
done

RETIRED_DESKTOPS=(
    "alien-webapp-whatsapp-web.desktop"
    "alien-webapp-whatsapp.desktop"
    "alien-webapp-instagram.desktop"
    "alien-webapp-tiktok.desktop"
    "alien-webapp-youtube.desktop"
    "alien-webapp-spotify.desktop"
    "alien-player.desktop"
    "alien-viewer.desktop"
    "alien-notes.desktop"
)

for rdt in "${RETIRED_DESKTOPS[@]}"; do
    if [ -f "$ROOTFS/usr/share/applications/$rdt" ]; then
        record_result "FAIL" "RETIRED-DT" "$rdt" "still present in applications"
    else
        record_result "OK" "RETIRED-DT" "$rdt" "properly purged"
    fi
done

echo
echo "--- 3. Required Desktop Entries (/usr/share/applications) ---"
REQUIRED_DESKTOPS=(
    "brave-browser.desktop"
    "vlc.desktop"
    "lximage-qt.desktop"
    "ghostwriter.desktop"
    "featherpad.desktop"
    "alien-store.desktop"
)

for dt in "${REQUIRED_DESKTOPS[@]}"; do
    dt_path="$ROOTFS/usr/share/applications/$dt"
    if [ ! -f "$dt_path" ] && [ "$dt" = "ghostwriter.desktop" ]; then
        dt_path="$ROOTFS/usr/share/applications/org.kde.ghostwriter.desktop"
    fi
    if [ -f "$dt_path" ]; then
        exec_val=$(grep -m1 '^Exec=' "$dt_path" | cut -d= -f2- || true)
        icon_val=$(grep -m1 '^Icon=' "$dt_path" | cut -d= -f2- || true)
        record_result "OK" "DESKTOP" "$dt" "Exec='$exec_val' Icon='$icon_val'"
    else
        record_result "FAIL" "DESKTOP" "$dt" "MISSING"
    fi
done

echo
echo "--- 4. Single Store Guarantee ---"
INSTALLED_STORES=0
if grep -q "Package: synaptic" "$ROOTFS/var/lib/dpkg/status" 2>/dev/null; then
    record_result "OK" "STORE-AUDIT" "synaptic" "installed as lightweight store substrate"
    INSTALLED_STORES=$((INSTALLED_STORES + 1))
fi
if grep -q "Package: cosmic-store" "$ROOTFS/var/lib/dpkg/status" 2>/dev/null; then
    record_result "OK" "STORE-AUDIT" "cosmic-store" "installed as COSMIC Store substrate"
    INSTALLED_STORES=$((INSTALLED_STORES + 1))
fi
if grep -q "Package: gnome-software" "$ROOTFS/var/lib/dpkg/status" 2>/dev/null; then
    record_result "FAIL" "EXTRA-STORE" "gnome-software" "extra store present"
fi
if grep -q "Package: discover" "$ROOTFS/var/lib/dpkg/status" 2>/dev/null; then
    record_result "FAIL" "EXTRA-STORE" "discover" "extra store present"
fi

if [ "$INSTALLED_STORES" -eq 1 ]; then
    record_result "OK" "STORE-COUNT" "exactly-one" "Exactly 1 store installed"
elif [ "$INSTALLED_STORES" -gt 1 ]; then
    record_result "FAIL" "STORE-COUNT" "multiple" "$INSTALLED_STORES stores installed"
else
    record_result "FAIL" "STORE-COUNT" "none" "Zero stores installed"
fi

echo
echo "--- 5. Panel Defaults & MIME Settings ---"
PANEL_CONF="$ROOTFS/etc/skel/.config/lxqt/panel.conf"
if [ -f "$PANEL_CONF" ]; then
    record_result "OK" "PANEL-CONF" "$PANEL_CONF" "exists"
    # Verify core pins
    for pin in pcmanfm-qt brave-browser vlc lximage-qt ghostwriter alien-store qterminal featherpad lxqt-config; do
        if grep -q "$pin" "$PANEL_CONF"; then
            record_result "OK" "PIN" "$pin" "present in Quick Launch"
        else
            record_result "FAIL" "PIN" "$pin" "MISSING from Quick Launch"
        fi
    done
    # Verify no retired pins
    for rpin in whatsapp instagram tiktok youtube spotify alien-player alien-viewer alien-notes; do
        if grep -qi "$rpin" "$PANEL_CONF"; then
            record_result "FAIL" "RETIRED-PIN" "$rpin" "still present in panel.conf"
        else
            record_result "OK" "RETIRED-PIN" "$rpin" "absent from panel.conf"
        fi
    done
else
    record_result "FAIL" "PANEL-CONF" "$PANEL_CONF" "MISSING"
fi

MIME_CONF="$ROOTFS/etc/skel/.config/mimeapps.list"
if [ -f "$MIME_CONF" ]; then
    record_result "OK" "MIME-CONF" "$MIME_CONF" "exists"
    grep -q "video/mp4=vlc.desktop" "$MIME_CONF" && record_result "OK" "MIME" "video/mp4" "maps to vlc.desktop" || record_result "FAIL" "MIME" "video/mp4" "incorrect mapping"
    grep -q "image/png=lximage-qt.desktop" "$MIME_CONF" && record_result "OK" "MIME" "image/png" "maps to lximage-qt.desktop" || record_result "FAIL" "MIME" "image/png" "incorrect mapping"
    grep -q "text/markdown=ghostwriter.desktop" "$MIME_CONF" && record_result "OK" "MIME" "text/markdown" "maps to ghostwriter.desktop" || record_result "FAIL" "MIME" "text/markdown" "incorrect mapping"
    grep -q "text/plain=featherpad.desktop" "$MIME_CONF" && record_result "OK" "MIME" "text/plain" "maps to featherpad.desktop" || record_result "FAIL" "MIME" "text/plain" "incorrect mapping"
    grep -q "x-scheme-handler/https=brave-browser.desktop" "$MIME_CONF" && record_result "OK" "MIME" "x-scheme-handler/https" "maps to brave-browser.desktop" || record_result "FAIL" "MIME" "x-scheme-handler/https" "incorrect mapping"
else
    record_result "FAIL" "MIME-CONF" "$MIME_CONF" "MISSING"
fi

echo
echo "--- 6. Plymouth & Bootloader Inspection ---"
if [ -f "$ROOTFS/etc/plymouth/plymouthd.conf" ]; then
    grep -q "Theme=alien" "$ROOTFS/etc/plymouth/plymouthd.conf" && record_result "OK" "PLYMOUTH-THEME" "alien" "set as default theme" || record_result "FAIL" "PLYMOUTH-THEME" "alien" "not set in plymouthd.conf"
    grep -q "ShowDelay=0" "$ROOTFS/etc/plymouth/plymouthd.conf" && record_result "OK" "PLYMOUTH-DELAY" "ShowDelay=0" "ShowDelay is 0" || record_result "FAIL" "PLYMOUTH-DELAY" "ShowDelay" "ShowDelay not 0"
else
    record_result "FAIL" "PLYMOUTH-CONF" "/etc/plymouth/plymouthd.conf" "MISSING"
fi

if [ -f "$TMPDIR/grub.cfg" ]; then
    grep -q "set timeout_style=hidden" "$TMPDIR/grub.cfg" && record_result "OK" "GRUB-HIDDEN" "timeout_style" "hidden menu configured" || record_result "FAIL" "GRUB-HIDDEN" "timeout_style" "not hidden"
    grep -q "set timeout=1" "$TMPDIR/grub.cfg" && record_result "OK" "GRUB-TIMEOUT" "timeout=1" "1s menu window" || record_result "FAIL" "GRUB-TIMEOUT" "timeout" "not 1s"
    grep -q "quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0" "$TMPDIR/grub.cfg" && record_result "OK" "GRUB-CMDLINE" "quiet-splash" "silent splash parameters present" || record_result "FAIL" "GRUB-CMDLINE" "quiet-splash" "parameters missing"
fi

echo
echo "--- 7. Build Stamp ---"
if [ -f "$ROOTFS/etc/alien-build" ]; then
    STAMP=$(cat "$ROOTFS/etc/alien-build" | tr -d '[:space:]')
    record_result "OK" "BUILD-STAMP" "/etc/alien-build" "$STAMP"
else
    record_result "FAIL" "BUILD-STAMP" "/etc/alien-build" "MISSING"
fi

echo
echo "--- 8. Wallpaper Package & Configuration Gate ---"
# Check alien-wallpapers installed
if grep -q "Package: alien-wallpapers" "$ROOTFS/var/lib/dpkg/status" 2>/dev/null; then
    record_result "OK" "WALLPAPER-PKG" "alien-wallpapers" "package installed in status database"
else
    record_result "FAIL" "WALLPAPER-PKG" "alien-wallpapers" "package missing from status database"
fi

if grep -q "Package: alien-wallpaper-migrate" "$ROOTFS/var/lib/dpkg/status" 2>/dev/null; then
    record_result "OK" "WALLPAPER-PKG" "alien-wallpaper-migrate" "migration package installed"
else
    record_result "FAIL" "WALLPAPER-PKG" "alien-wallpaper-migrate" "migration package missing"
fi

# Check all 11 wallpapers exist and non-empty
WALLPAPER_DIR="$ROOTFS/usr/share/backgrounds/alien"
EXPECTED_WP=(
    "Alien-Default.png"
    "Alien-Default-1080p.png"
    "Alien-Panel-1-1.png"
    "Alien-Panel-1-2.png"
    "Alien-Panel-1-3.png"
    "Alien-Panel-2-1.png"
    "Alien-Panel-2-2.png"
    "Alien-Panel-2-3.png"
    "Alien-Panel-3-2.png"
    "Alien-Panel-3-3.png"
    "Alien-Sky.png"
    "Alien-Neon.png"
)

if [ -d "$WALLPAPER_DIR" ]; then
    record_result "OK" "WALLPAPER-DIR" "$WALLPAPER_DIR" "directory exists"
    for wp in "${EXPECTED_WP[@]}"; do
        if [ -s "$WALLPAPER_DIR/$wp" ]; then
            record_result "OK" "WALLPAPER-FILE" "$wp" "present ($(stat -c%s "$WALLPAPER_DIR/$wp" 2>/dev/null || echo '?') bytes)"
        else
            record_result "FAIL" "WALLPAPER-FILE" "$wp" "missing or empty"
        fi
    done

    # Check default.png symlink
    if [ -L "$WALLPAPER_DIR/default.png" ]; then
        target=$(readlink "$WALLPAPER_DIR/default.png")
        if [ "$target" = "Alien-Default.png" ]; then
            record_result "OK" "WALLPAPER-LINK" "default.png" "symlink points to Alien-Default.png"
        else
            record_result "FAIL" "WALLPAPER-LINK" "default.png" "symlink points to $target (expected Alien-Default.png)"
        fi
    else
        record_result "FAIL" "WALLPAPER-LINK" "default.png" "symlink missing"
    fi
else
    record_result "FAIL" "WALLPAPER-DIR" "$WALLPAPER_DIR" "directory missing"
fi

# Check skel and etc/xdg pcmanfm-qt configuration
SKEL_PCMANFM_CONF="$ROOTFS/etc/skel/.config/pcmanfm-qt/lxqt/settings.conf"
if [ -f "$SKEL_PCMANFM_CONF" ]; then
    if grep -q "/usr/share/backgrounds/alien/default.png" "$SKEL_PCMANFM_CONF"; then
        record_result "OK" "WALLPAPER-SKEL" "settings.conf" "points to default.png"
    else
        record_result "FAIL" "WALLPAPER-SKEL" "settings.conf" "does not point to default.png"
    fi
    if grep -qi "WallpaperMode=zoom" "$SKEL_PCMANFM_CONF"; then
        record_result "OK" "WALLPAPER-SKEL" "mode" "WallpaperMode=zoom"
    else
        record_result "FAIL" "WALLPAPER-SKEL" "mode" "WallpaperMode not zoom"
    fi
else
    record_result "FAIL" "WALLPAPER-SKEL" "settings.conf" "missing in etc/skel"
fi

XDG_PCMANFM_CONF="$ROOTFS/etc/xdg/pcmanfm-qt/lxqt/settings.conf"
if [ -f "$XDG_PCMANFM_CONF" ]; then
    if grep -q "/usr/share/backgrounds/alien/default.png" "$XDG_PCMANFM_CONF"; then
        record_result "OK" "WALLPAPER-XDG" "settings.conf" "points to default.png"
    else
        record_result "FAIL" "WALLPAPER-XDG" "settings.conf" "does not point to default.png"
    fi
    if grep -qi "WallpaperMode=zoom" "$XDG_PCMANFM_CONF"; then
        record_result "OK" "WALLPAPER-XDG" "mode" "WallpaperMode=zoom"
    else
        record_result "FAIL" "WALLPAPER-XDG" "mode" "WallpaperMode not zoom"
    fi
else
    record_result "FAIL" "WALLPAPER-XDG" "settings.conf" "missing in etc/xdg"
fi

echo "============================================================"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo " Inspection Summary: ALL CHECKS PASSED (0 failures)."
    exit 0
else
    echo " Inspection Summary: $FAIL_COUNT failure(s) detected."
    exit 1
fi
echo "============================================================"
