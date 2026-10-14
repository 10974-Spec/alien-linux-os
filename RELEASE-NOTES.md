# Alien OS v0.1.0 (Lite Edition) — First Public Release

Welcome to the first public release of **Alien OS (Lite Edition)**!

Alien OS is a Debian-based Linux distribution built for low resource consumption, snappy desktop responsiveness, and out-of-the-box productivity with curated native applications.

---

## What's in This Release

- **Base System**: Debian GNU/Linux 13 (Trixie) with Linux kernel 6.12+ (x86_64).
- **Desktop Environment**: LXQt 2.1 desktop with Openbox window manager and Picom compositor for tear-free rendering.
- **Resource Footprint**: Boots to a clean desktop using ~480 MB idle RAM.
- **Curated Applications**:
  - **Browser**: Brave Browser (privacy-focused, hardware-accelerated).
  - **Media Player**: VLC media player (pre-bundled with universal codecs).
  - **Image Viewer**: LXImage-Qt (fast image viewer with thumbnail support).
  - **Notes & Writing**: Ghostwriter (Markdown editor) and FeatherPad (lightweight text editor).
  - **Package Management**: Synaptic Package Manager with AppStream support.
  - **Terminal**: QTerminal with customized prompt styling.
- **Wallpapers & Branding**:
  - 11 high-definition Alien wallpapers installed in `/usr/share/backgrounds/alien/`.
  - Default wallpaper: `panel_3_1` (`Alien-Default.png`).
  - Wallpaper chooser integrated directly into the LXQt Preferences menu.
- **Boot Experience**:
  - Plymouth graphical boot splash.
  - Clean UEFI and BIOS bootloader configuration with hidden menu and silent boot handoff.

---

## Release Asset Specifications

- **Build ID:** `20261014-1409-5cadbfc`
- **Architecture:** `amd64` (x86_64)
- **Target ISO Size:** 2,593,005,568 bytes (~2.41 GiB)

Because GitHub Release assets are limited to 2 GiB per file, the ISO is distributed in two split parts:
- `alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.00.part` (1.9 GB)
- `alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.01.part` (573 MB)

### How to Rejoin the ISO
Download both part files and `SHA256SUMS` into the same directory, then run:

```bash
# Verify parts integrity:
sha256sum -c SHA256SUMS

# Rejoin parts into the complete bootable ISO:
cat alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.*.part > alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso

# Verify the joined ISO:
sha256sum alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso
```

### Official SHA-256 Checksums
```text
f0d51e03ebcaa7dc264dc68913f51a3f7e40351dbe99d00e42d8c3374b1fda47  alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso
6d6e5849149e76afb2cec87cf447317c90e5200729317b4d2382bf284c7bdca6  alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.00.part
6ac565913e8efc735cc08e48806f653dc5bdaebee3396f65cf73400c70310022  alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.01.part
```

---

## System Requirements

- **Processor**: 64-bit x86 dual-core processor (1.6 GHz or faster).
- **RAM**: Minimum 2 GB (4 GB recommended for comfortable multitasking and Brave browsing).
- **Storage**: Minimum 20 GB free disk space for installation.
- **Boot Firmware**: UEFI with Secure Boot (MOK enrolled) or standard Legacy BIOS.

---

## Known Issues

- **High-DPI / Fractional Scaling**: Fractional scaling (e.g. 125%, 150%) under X11 is limited; use integer 2x scaling in LXQt Session Settings on 4K displays.
- **Touchpad Gestures**: Advanced multi-finger swipe gestures require manual configuration via `libinput-gestures`.

---

## Credits & Attributions

- Iconography based on Icons8 Color style: [Icons8](https://icons8.com).
- Papirus Icon Theme: [Papirus Development Team](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).
- Debian GNU/Linux Project: [Debian](https://www.debian.org).
- Upstream software teams: VideoLAN (VLC), LXQt Project, Brave Software, FeatherPad, and Ghostwriter.
