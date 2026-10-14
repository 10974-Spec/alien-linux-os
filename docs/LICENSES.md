# Alien OS Third-Party Licenses and Credits

This document details the software components, third-party libraries, and assets integrated into Alien OS.

---

## 1. Core Established Applications

### VLC media player
- **Component:** VLC Media Player (`vlc`, `vlc-plugin-base`, `vlc-plugin-qt`, `libavcodec-extra`)
- **License:** GNU General Public License v2+ (GPL-2.0+) / GNU Lesser General Public License v2.1+ (LGPL-2.1+)
- **Copyright:** (C) 1996-present VideoLAN and VLC authors
- **Website:** https://www.videolan.org/vlc/

### lximage-qt
- **Component:** LXQt Image Viewer (`lximage-qt`)
- **License:** GNU General Public License v2+ (GPL-2.0+)
- **Copyright:** (C) The LXQt Project Developers
- **Website:** https://github.com/lxqt/lximage-qt

### Ghostwriter
- **Component:** Markdown Text & Notes Editor (`ghostwriter`)
- **License:** GNU General Public License v3+ (GPL-3.0+)
- **Copyright:** (C) Megan Conkle, The KDE Community
- **Website:** https://ghostwriter.kde.org/

### FeatherPad
- **Component:** Lightweight Qt Plain Text Editor (`featherpad`)
- **License:** GNU General Public License v3+ (GPL-3.0+)
- **Copyright:** (C) Pedram Pourang (tsujan)
- **Website:** https://github.com/tsujan/FeatherPad

### Brave Browser
- **Component:** Brave Web Browser (`brave-browser`)
- **License:** Mozilla Public License 2.0 (MPL-2.0) / Chromium BSD-3-Clause
- **Copyright:** (C) Brave Software, Inc.
- **Website:** https://brave.com/

---

## 2. Desktop Environment & Utilities

### LXQt Desktop
- **Component:** LXQt Desktop (`lxqt-core`, `lxqt-panel`, `lxqt-session`, `lxqt-runner`, `pcmanfm-qt`)
- **License:** GNU LGPL v2.1+ / GNU GPL v2+
- **Copyright:** The LXQt Project Developers
- **Website:** https://lxqt-project.org/

### Window Manager & Compositor
- **Component:** Openbox (`openbox`), Picom Compositor (`picom`)
- **License:** GNU GPL v2 / MIT
- **Copyright:** Dana Jansens, Mikael Magnusson, Derek Foreman, Yuxuan Shui, et al.

### Software Center & Package Management
- **Component:** Synaptic (`synaptic`), PackageKit (`packagekit`), AppStream (`appstream`)
- **License:** GNU GPL v2+ / GNU LGPL v2.1+
- **Copyright:** Michael Vogt, Alfredo K. Kojima, Conectiva S/A, Richard Hughes, Matthias Klumpp, et al.

---

## 3. Icons, Artwork & Attribution

### Papirus Icon Theme
- **Component:** Papirus Icon Theme (`papirus-icon-theme`)
- **License:** GNU General Public License v3 (GPL-3.0)
- **Copyright:** (C) Papirus Development Team
- **Website:** https://github.com/PapirusDevelopmentTeam/papirus-icon-theme

### Icons8 Colored Artwork
- **Component:** Colored application icons (Video Player, Image Viewer, Notes, Store)
- **Provider:** Icons8 (https://icons8.com)
- **Attribution Notice:** Application iconography based on Icons8 Color style (https://icons8.com).
- **Public Distribution Notice:** Free tier usage requires backlink attribution to https://icons8.com. Public redistribution of binary ISO images requires a license that permits redistribution under Icons8 terms, or fallback to the FLOSS Papirus colored icon set.

### Alien OS Custom Branding
- **Logos & UI Artwork:** Alien Project (Original Artwork)
- **Alien Look-and-Feel & Wallpapers:** Alien Project
- **License:** MIT License
- **Copyright:** (C) Alien OS Team

---

## Alien OS Official Wallpapers (`alien-wallpapers` package)

- **Component:** `alien-wallpapers` package — 11 background images shipped in `/usr/share/backgrounds/alien/`
- **Files:** `Alien-Default.png`, `Alien-Default-1080p.png`, `Alien-Panel-1-1.png`, `Alien-Panel-1-2.png`, `Alien-Panel-1-3.png`, `Alien-Panel-2-1.png`, `Alien-Panel-2-2.png`, `Alien-Panel-2-3.png`, `Alien-Panel-3-2.png`, `Alien-Panel-3-3.png`, `Alien-Sky.png`, `Alien-Neon.png` (plus stable symlink `default.png` → `Alien-Default.png`).
- **Source assets:** `branding-assets/bg/` (11 files — SVGs with embedded raster content, plus `bg2.png`)
- **Author:** Original artwork by the Alien OS creator. All rights reserved.
- **License:** Permission granted for use within Alien OS and its derivative builds. Not for redistribution outside Alien OS.
- **SPDX identifier:** `LicenseRef-AlienOS-Wallpapers-Proprietary`
- **Rendered at build time** by `branding/build-wallpapers.py` using `rsvg-convert` (librsvg); source SVGs are not shipped in the ISO.
- **Manifest:** `branding/wallpapers.yaml` — edit to rename wallpapers or change the default.
