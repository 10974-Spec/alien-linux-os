# Changelog
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-10

### Added
- **Real Logo Terminal Banner**:
  - Replaced ASCII triangle with real Alien logo ANSI art ("sticker" white panel on dark terminal background, side-by-side system info column).
  - High-performance `alien-banner` (< 30 ms execution time; benchmarked at 21.12 ms avg).
  - TTY and interactive shell detection, subshell recursion guard (`_ALIEN_BANNER_TTY`), and opt-out support via `~/.config/alien/no-banner`.
  - ANSI 24-bit truecolor, 16-color fallback, and optional Sixel pixel-exact art.
- **Unified GRUB Architecture**:
  - High-resolution branded Alien graphical GRUB theme shared across BIOS and UEFI.
  - Submenu structure: Default, Advanced options (previous kernels/recovery), Snapshots & Rollbacks, Tools & Diagnostics (memtest86+, UEFI firmware setup, reboot, power off).
  - Automated boot assessment counter via ESP `grubenv` (`01_alien_boot_counter` and `alien-boot-good.service`) providing automated fallback to previous kernel/snapshots on failed boots.
  - `panic=10` kernel parameter for clean reboot on kernel panic.
- **Btrfs Default Layout & Snapper**:
  - Calamares default Btrfs installation with `@`, `@home`, `@snapshots`, `@var_log`, and `@var_cache` subvolumes.
  - Transparent `zstd:1` compression, `noatime`, `space_cache=v2`, and `discard=async` mount parameters.
  - Pre and post APT transaction snapshot hooks (`80-alien-snapper`).
  - Dynamic GRUB snapshot menu entry generation (`41_snapshots-btrfs`).
  - `alien-snapshot` CLI and `alien-recover` graphical recovery utility.
- **Protected System Mode (`alien-protect`)**:
  - Opt-in read-only `/usr` mounting with `/usr/local` writable bind mount.
  - Automated `DPkg::Pre-Invoke` and `DPkg::Post-Invoke` hooks for safe package transactions.
- **Dynamic RAM-Fit Logic**:
  - `alien.toram=auto` evaluating `MemTotal` before root mount; copies to RAM on systems with >= 3.5GB RAM, boots via page cache on low-RAM systems.
- **Performance & Resource Slicing**:
  - `systemd-zram-generator` with zstd compressed swap.
  - `app.slice` (high priority for interactive session & audio) and `dev.slice` (constrained CPU/IO and 80% MemoryHigh limit for background developer workloads).
  - `alien-dev-run` and `systemd-oomd` memory pressure monitoring.
  - Hardware-aware `alien-tune` service and profile engine.
- **Developer Sandboxes & Hardware Stacks**:
  - `alien-sandbox` for rootless, ephemeral containerized developer environments.
  - PipeWire real-time audio profiles via `alien-audio-profile` (`desktop`, `low-latency`, `pro-audio`).
  - Hardware video decode pre-configuration (`mpv.conf`, Brave flags) and `alien-gpu-check`.
- **Safety Nets & Health Diagnostics**:
  - `alien-guard` interactive shell command confirmation hook protecting `/`, `~`, block devices, and raw piping.
  - `alien-doctor` diagnostic engine.
  - Extended tiered package management via `alien-pkg`.
  - Architecture `.deb` package definitions in `packages/`.

