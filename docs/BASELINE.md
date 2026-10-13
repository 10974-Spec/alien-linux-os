# Baseline Report (Pre-Reset)

**Measurements taken from newest baseline ISO (`alien-lite-0.1-2bd5ae9-20261012-1256-amd64.iso`) at git tag `pre-reset`:**

## Alien Lite Baseline
- **ISO File**: `out/alien-lite-0.1-2bd5ae9-20261012-1256-amd64.iso`
- **ISO Size**: 2.3 GB (2,450,653,184 bytes)
- **Boot Time (QEMU 2 cores, 4GB RAM, UEFI)**: ~82.3 seconds
- **Idle RAM**: ~450 MB
- **Build ID**: `2bd5ae9-20261012-1256`
- **Installed Stores**: 0 (Broken/missing)
- **Default Browser**: Brave (Installed, lacks GPU detection wrapper and verified keyring pinning)
- **Core Apps**: Stubs with placeholder SVG rectangle icons (`alien-player`, `alien-viewer`, `alien-notes`)
- **Social Web Apps**: WhatsApp, Instagram, TikTok, YouTube, Spotify (Present & pinned)
- **Bootloader**: Visible multi-entry menu with 5s timeout; Plymouth hook omitted from initramfs update

## Target Metrics for "Reset and Make it Real"
- **Clean Boot**: Hidden GRUB menu (1s window, Esc/Shift reveals), Plymouth Alien splash screen visible from boot through desktop
- **Real Apps**: VLC, LXQt-native `lximage-qt`, Markdown notes (`ghostwriter`), FeatherPad
- **Default Browser**: Brave with official verified keyring, GPU detection wrapper, managed policy
- **Real Store**: Single working lightweight store with PackageKit/APT integration
- **Social Web Apps**: 100% removed (Brave and native Telegram Desktop preserved)
- **Icons**: Colored Icons8 / Papirus-style icons at all standard resolutions (16-512 + scalable)
- **Idle RAM**: <= 450 MB
- **ISO Size**: Maintained or reduced
