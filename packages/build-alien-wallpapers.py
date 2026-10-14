#!/usr/bin/env python3
"""
Alien OS — Package alien-wallpapers deb package
Constructs packages/alien-wallpapers and builds packages/alien-wallpapers.deb
SPDX-License-Identifier: MIT
"""

import os
import shutil
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WALLPAPERS_SRC = os.path.join(ROOT, "branding", "generated", "wallpapers")
PKG_DIR = os.path.join(ROOT, "packages", "alien-wallpapers")
DEB_FILE = os.path.join(ROOT, "packages", "alien-wallpapers.deb")

def main():
    print("=== Building alien-wallpapers package ===")

    # Ensure source wallpapers exist
    if not os.path.exists(WALLPAPERS_SRC) or not os.path.exists(os.path.join(WALLPAPERS_SRC, "Alien-Default.png")):
        print("Rendering wallpapers first via build-wallpapers.py...")
        subprocess.run(["python3", os.path.join(ROOT, "branding", "build-wallpapers.py")], check=True)

    # Clean existing package build dir
    if os.path.exists(PKG_DIR):
        shutil.rmtree(PKG_DIR)

    debian_dir = os.path.join(PKG_DIR, "DEBIAN")
    bg_alien_dir = os.path.join(PKG_DIR, "usr", "share", "backgrounds", "alien")
    bg_parent_dir = os.path.join(PKG_DIR, "usr", "share", "backgrounds")
    metainfo_dir = os.path.join(PKG_DIR, "usr", "share", "metainfo")
    doc_dir = os.path.join(PKG_DIR, "usr", "share", "doc", "alien-wallpapers")

    os.makedirs(debian_dir, exist_ok=True)
    os.makedirs(bg_alien_dir, exist_ok=True)
    os.makedirs(metainfo_dir, exist_ok=True)
    os.makedirs(doc_dir, exist_ok=True)

    # 1. DEBIAN/control
    control_text = """Package: alien-wallpapers
Version: 1.0.0-1
Section: x11
Priority: optional
Architecture: all
Maintainer: Alien OS Team <team@alienos.org>
Description: Official wallpapers for Alien OS
 A curated collection of 11 wallpapers for Alien OS, including Alien-Default
 (Panel 3.1), 8 dark sci-fi panel variants, Alien-Sky, and Alien-Neon.
 Original artwork by Alien creator, licensed for use in Alien OS.
"""
    with open(os.path.join(debian_dir, "control"), "w", encoding="utf-8") as f:
        f.write(control_text)

    # 2. Copy wallpapers into /usr/share/backgrounds/alien/
    shipped_files = [
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
    ]

    for fname in shipped_files:
        src = os.path.join(WALLPAPERS_SRC, fname)
        if not os.path.exists(src):
            raise FileNotFoundError(f"Missing required wallpaper file: {src}")
        shutil.copy2(src, os.path.join(bg_alien_dir, fname))
        print(f"  + Included {fname}")

    # 3. Stable default symlink inside /usr/share/backgrounds/alien/
    # /usr/share/backgrounds/alien/default.png -> Alien-Default.png
    os.symlink("Alien-Default.png", os.path.join(bg_alien_dir, "default.png"))
    # Also relative internal symlinks for old names if referenced within alien/
    os.symlink("Alien-Default.png", os.path.join(bg_alien_dir, "alien-bg1.png"))
    os.symlink("Alien-Neon.png", os.path.join(bg_alien_dir, "alien-bg2.png"))

    # 4. Legacy compatibility symlinks in /usr/share/backgrounds/
    # /usr/share/backgrounds/default.png -> alien/default.png
    os.symlink("alien/default.png", os.path.join(bg_parent_dir, "default.png"))
    os.symlink("alien/Alien-Default.png", os.path.join(bg_parent_dir, "alien-bg1.png"))
    os.symlink("alien/Alien-Neon.png", os.path.join(bg_parent_dir, "alien-bg2.png"))

    # 5. AppStream Metainfo
    metainfo_xml = """<?xml version="1.0" encoding="UTF-8"?>
<component type="generic">
  <id>org.alien.wallpapers</id>
  <name>Alien Wallpapers</name>
  <summary>Official wallpaper artwork collection for Alien OS</summary>
  <metadata_license>MIT</metadata_license>
  <project_license>Proprietary</project_license>
  <description>
    <p>
      Official curated collection of 11 wallpapers designed for Alien OS.
      Includes Alien-Default (Panel 3.1) in 4K and 1080p, 8 dark sci-fi panel
      variations, Alien-Sky, and Alien-Neon.
    </p>
  </description>
  <developer id="org.alien">
    <name>Alien OS Project</name>
  </developer>
</component>
"""
    with open(os.path.join(metainfo_dir, "alien-wallpapers.metainfo.xml"), "w", encoding="utf-8") as f:
        f.write(metainfo_xml)

    # 6. Copyright and Credits
    copyright_txt = """Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: alien-wallpapers
Source: https://alienos.org

Files: *
Copyright: (C) Alien OS Author
License: Custom-Alien-Artwork
 All wallpaper images (panel_1_1 through panel_3_3, bg1, and bg2) are original
 artwork created by the author of Alien OS, licensed for distribution and use
 within Alien OS.
"""
    with open(os.path.join(doc_dir, "copyright"), "w", encoding="utf-8") as f:
        f.write(copyright_txt)

    # 7. Build deb package
    print("Building debian package with dpkg-deb...")
    subprocess.run(["dpkg-deb", "--build", PKG_DIR, DEB_FILE], check=True)
    size_deb = os.path.getsize(DEB_FILE)
    print(f"Successfully built {DEB_FILE} ({size_deb / (1024*1024):.2f} MB)")

    # Verify package contents
    res = subprocess.run(["dpkg-deb", "-c", DEB_FILE], stdout=subprocess.PIPE, text=True, check=True)
    print("Package contents verified:")
    for line in res.stdout.strip().split("\n"):
        if "backgrounds" in line or "metainfo" in line:
            print(f"  {line}")

if __name__ == "__main__":
    main()
