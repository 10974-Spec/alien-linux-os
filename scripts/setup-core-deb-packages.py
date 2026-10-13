#!/usr/bin/env python3
"""
Setup DEBIAN control structures for alien-player, alien-viewer, alien-notes, alien-store, alien-webapp.
"""
import os
import shutil
import subprocess

ROOT = "/home/nyakoe/Desktop/alien"
PACKAGES_DIR = os.path.join(ROOT, "packages")
TOOLS_DIR = os.path.join(ROOT, "tools")

PKGS = {
    "alien-player": {
        "version": "1.0.0-1",
        "section": "video",
        "depends": "bash, mpv",
        "desc": "Alien OS media and video player\n Sleek, high-performance video and media player for Alien OS.",
        "tool": "alien-player/alien-player",
    },
    "alien-viewer": {
        "version": "1.0.0-1",
        "section": "graphics",
        "depends": "bash, lximage-qt",
        "desc": "Alien OS image viewer\n Lightweight, responsive image viewer for Alien OS.",
        "tool": "alien-viewer/alien-viewer",
    },
    "alien-notes": {
        "version": "1.0.0-1",
        "section": "text",
        "depends": "bash, featherpad",
        "desc": "Alien OS Markdown notes and text editor\n Markdown notes manager with ~/Notes/ storage and quick capture.",
        "tool": "alien-notes/alien-notes",
    },
    "alien-store": {
        "version": "1.0.0-1",
        "section": "admin",
        "depends": "bash, libflatpak0, libxkbcommon0",
        "desc": "Alien OS Software Center\n Rebranded COSMIC Store 1.0.0 for Alien OS with software rasterizer support.",
        "tool": "alien-store/alien-store",
    },
    "alien-webapp": {
        "version": "1.0.0-1",
        "section": "web",
        "depends": "bash, brave-browser",
        "desc": "Alien OS web application launcher\n Multi-profile isolated web application runner for Brave Browser.",
        "tool": "alien-webapp/alien-webapp",
    },
}

for name, meta in PKGS.items():
    pkg_root = os.path.join(PACKAGES_DIR, name)
    debian_dir = os.path.join(pkg_root, "DEBIAN")
    bin_dir = os.path.join(pkg_root, "usr", "bin")
    os.makedirs(debian_dir, exist_ok=True)
    os.makedirs(bin_dir, exist_ok=True)

    control_content = f"""Package: {name}
Version: {meta['version']}
Section: {meta['section']}
Priority: optional
Architecture: all
Depends: {meta['depends']}
Maintainer: Alien OS Team <team@alienos.org>
Description: {meta['desc']}
"""
    with open(os.path.join(debian_dir, "control"), "w") as f:
        f.write(control_content)

    src_tool = os.path.join(TOOLS_DIR, meta['tool'])
    if os.path.exists(src_tool):
        dest_bin = os.path.join(bin_dir, name)
        shutil.copy2(src_tool, dest_bin)
        os.chmod(dest_bin, 0o755)

    print(f"Configured package structure for {name}")

# Now build packages
subprocess.run(["bash", os.path.join(PACKAGES_DIR, "build-packages.sh")], check=True)
print("All packages built successfully.")
