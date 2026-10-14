#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# tests/check-wallpapers-gate.py
# Gate check: verifies alien-wallpapers.deb exists and contains all required files.
# Run by: make check-wallpapers
import subprocess
import sys
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DEB = os.path.join(ROOT, "packages", "alien-wallpapers.deb")
CHROOT_DEB = os.path.join(ROOT, "layers", "shared", "packages.chroot", "alien-wallpapers.deb")

EXPECTED_FILES = [
    "Alien-Default.png",
    "Alien-Default-1080p.png",
    "Alien-Panel-1-1.png",
    "Alien-Panel-1-2.png",
    "Alien-Panel-1-3.png",
    "Alien-Panel-2-1.png",
    "Alien-Panel-2-2.png",
    "Alien-Panel-2-3.png",
    "Alien-Panel-3-2.png",
    "Alien-Panel-3-3.png",
    "Alien-Sky.png",
    "Alien-Neon.png",
    "default.png",
    "alien-bg1.png",
    "alien-bg2.png",
]

failures = 0

# 1. Check the .deb exists
if not os.path.exists(DEB):
    print(f"FAIL: {DEB} does not exist. Run 'make wallpapers' then build-alien-wallpapers.py")
    sys.exit(1)

# 2. Check all 11+extras are in the .deb
contents = subprocess.check_output(["dpkg-deb", "--contents", DEB], text=True)
missing = [f for f in EXPECTED_FILES if f not in contents]
if missing:
    print(f"FAIL: Missing files in .deb: {missing}")
    failures += 1
else:
    print(f"PASS: alien-wallpapers.deb contains all {len(EXPECTED_FILES)} required entries.")

# 3. Check the .deb is in live-build packages.chroot
if not os.path.exists(CHROOT_DEB):
    print(f"FAIL: alien-wallpapers.deb not found in layers/shared/packages.chroot/")
    failures += 1
else:
    print(f"PASS: alien-wallpapers.deb present in live-build chroot.")

# 4. Check default.png symlink points to Alien-Default.png
if "default.png -> Alien-Default.png" not in contents:
    print("FAIL: default.png symlink not pointing to Alien-Default.png")
    failures += 1
else:
    print("PASS: default.png -> Alien-Default.png symlink present.")

# 5. Check skel/xdg config points to new path
lxqt_defaults = os.path.join(ROOT, "build", "assemble.d", "lxqt-defaults.sh")
with open(lxqt_defaults) as f:
    lxqt_content = f.read()
if "/usr/share/backgrounds/alien/default.png" not in lxqt_content:
    print("FAIL: lxqt-defaults.sh does not reference the new wallpaper path.")
    failures += 1
else:
    print("PASS: lxqt-defaults.sh references /usr/share/backgrounds/alien/default.png")

if "WallpaperMode=zoom" not in lxqt_content:
    print("FAIL: lxqt-defaults.sh does not set WallpaperMode=zoom")
    failures += 1
else:
    print("PASS: lxqt-defaults.sh sets WallpaperMode=zoom")

print("")
if failures > 0:
    print(f"GATE FAILED: {failures} check(s) failed.")
    sys.exit(1)
print("GATE PASSED: All wallpaper checks green.")
