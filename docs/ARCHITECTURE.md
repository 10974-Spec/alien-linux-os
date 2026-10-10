# Alien OS Architecture Specification

## 1. Overview and Design Principles

Alien OS is a Debian 13 ("Trixie") distribution built with `live-build` inside an isolated container environment. It delivers a lightweight, highly responsive operating system in two editions:
- **Alien Lite**: LXQt on X11 with Openbox window manager, tailored for efficiency and low-resource hardware.
- **Alien Full**: KDE Plasma on Wayland/X11 for modern hardware.

The core architecture adheres to four engineering principles:
1. **Desktop Integrity**: Desktop layout, panel, Openbox themes, window decorations, and wallpapers remain stable and untouched.
2. **Debian Base Compliance**: Upstream Debian 13 packages, signed kernels, and systemd init are preserved without unsupported third-party kernel forks.
3. **Resilience & Unbrickability**: Software updates, driver failures, or crashes cannot render the system permanently unbootable. Automated fallbacks recover healthy system state.
4. **Hardware-Aware Performance**: Memory compression, CPU slicing, I/O scheduling, and battery thresholds adapt dynamically to the host machine's physical capabilities.

---

## 2. Boot Architecture & GRUB

### 2.1 Unified Theming & Secure Boot
Both BIOS and UEFI boot paths share an identical graphical GRUB theme located at `/boot/grub/themes/alien/`.
- Assets: High-resolution branded canvas, selection indicators, progress bars, and Unicode DejaVu fonts (`dejavu-14.pf2`, `dejavu-bold-14.pf2`).
- Signed Binaries: Debian's `shim-signed` and `grub-efi-amd64-signed` ensure seamless boot under UEFI Secure Boot.

### 2.2 Boot Menu Hierarchy
```
Alien OS
├── Alien OS (Default Kernel)
├── Advanced options for Alien OS
│   ├── Previous Kernel Entries
│   └── Recovery Mode
├── Snapshots & Rollbacks (Btrfs Snapper entries)
│   ├── Snapshot #12 (Pre-apt upgrade)
│   └── Snapshot #11 (Post-apt install)
└── Tools & Diagnostics
    ├── Memory Diagnostic (memtest86+)
    ├── UEFI Firmware Settings
    ├── Reboot System
    └── Power Off
```

### 2.3 Boot Assessment Counter & Fallback Engine
To prevent boot hangs after kernel or driver updates:
1. **Counter Mechanism**: `/etc/grub.d/01_alien_boot_counter` maintains `alien_boot_tries` (default 3). Each boot decrements the counter.
2. **ESP grubenv Storage**: Because GRUB cannot write environment files to Btrfs subvolumes, UEFI systems maintain `grubenv` on the FAT32 EFI System Partition (`/boot/efi/EFI/alien/grubenv`). GRUB loads and saves via `load_env -f` and `save_env -f`. (On BIOS, interactive recovery submenus provide equivalent manual recovery).
3. **Fallback Trigger**: When `alien_boot_tries` drops to 0, GRUB automatically boots the previous kernel or last known good snapshot, setting `timeout_style=menu` and displaying recovery diagnostics.
4. **Health Confirmation**: Once `graphical.target` and the display manager (`lightdm` / `sddm`) are active, `alien-boot-good.service` executes `/usr/bin/alien-boot-mark-good`, resetting `alien_boot_tries=3` and marking `alien_boot_success=1`.
5. **Kernel Panics**: Configured with `panic=10` to automatically reboot after 10 seconds rather than hanging indefinitely.

---

## 3. Storage Layout & Snapshot Subvolumes

### 3.1 Calamares Btrfs Schema
For installed systems, Calamares partitions the target drive using Btrfs with dedicated subvolumes:
- `@` -> `/` (Root operating system)
- `@home` -> `/home` (User home directories, isolated from system rollbacks)
- `@snapshots` -> `/.snapshots` (Snapper snapshot repository)
- `@var_log` -> `/var/log` (System log retention across rollbacks)
- `@var_cache` -> `/var/cache` (APT and application cache)

### 3.2 Mount Parameters
All subvolumes are mounted with:
```
noatime,compress=zstd:1,space_cache=v2,discard=async
```
Transparent `zstd:1` compression maximizes read/write throughput while reducing physical SSD write amplification.

### 3.3 Snapper & GRUB Snapshot Integration
- **APT Transaction Hooks**: `/etc/apt/apt.conf.d/80-alien-snapper` triggers `snapper create -t pre` and `snapper create -t post` around every `apt` install, remove, or upgrade action.
- **Dynamic GRUB Generation**: `/etc/grub.d/41_snapshots-btrfs` parses Snapper snapshots and automatically generates bootable snapshot menu items in GRUB upon `update-grub`.
- **Management Tools**:
  - `alien-snapshot`: CLI utility supporting `create`, `list`, `delete`, `rollback`, and `status` with `--dry-run` validation.
  - `alien-recover`: Interactive dialog listing snapshots with human-readable descriptions and a one-click "Restore this version" action.

---

## 4. Protected Mode (`alien-protect`)

`alien-protect` provides an opt-in read-only system root:
- When enabled, `/usr` is mounted read-only (`mount -o remount,ro /usr`), preventing accidental deletion or unauthorized tampering.
- `/usr/local` remains writable via a dedicated bind-mount for user scripts and custom toolchains.
- `/etc/apt/apt.conf.d/75-alien-protect` hooks automatically remount `/usr` read-write before APT operations and safely restore read-only state upon completion or failure.
- Default state is **OFF** to guarantee 100% standard Debian development workflows out-of-the-box.

---

## 5. Live Environment & RAM-Fit Logic

When booting from live USB media:
- **Automatic RAM-Fit (`alien.toram=auto`)**: `/etc/initramfs-tools/scripts/live-premount/alien-toram` measures physical `MemTotal`.
  - On systems with **>= 3,500 MB RAM**, it copies the root squashfs image into RAM (`toram`), enabling near-instant application launches and allowing the USB stick to be unplugged.
  - On low-resource systems (**< 3,500 MB RAM**), it boots directly from the USB drive via the standard Linux page cache, preventing out-of-memory lockups during boot.
- **Persistence**: Supported via the `persistence` boot option and secondary ext4/btrfs persistence partitions.

---

## 6. Performance Tuning & CGroup Slicing

### 6.1 Memory Optimization (ZRAM)
- `systemd-zram-generator` dynamically allocates compressed zstd swap in RAM sized to physical memory tiers.
- Tuned with `vm.swappiness=180` and `vm.page-cluster=0` for immediate compressed paging without hitting physical swap.

### 6.2 CGroup Slicing & OOM Protection
- **`app.slice`**: Assigned `CPUWeight=200`, `IOWeight=200` to prioritize the user session, audio daemon, and window manager.
- **`dev.slice`**: Assigned `CPUWeight=50`, `IOWeight=50`, and `MemoryHigh=80%` to constrain background compilation, heavy test runs, and containers.
- **`alien-dev-run <command>`**: Spawns developer commands scoped within `dev.slice`.
- **OOM Management**: Configured via `systemd-oomd` (`/etc/systemd/oomd.conf`) to terminate rogue processes within `dev.slice` under severe memory pressure before the interactive desktop session is compromised.

### 6.3 Hardware-Aware Profiles (`alien-tune`)
`alien-tune` evaluates hardware parameters:
- **I/O Scheduler**: Configures `none` for fast NVMe storage, `mq-deadline` or `bfq` for rotational HDDs.
- **Laptop Power**: Configures TLP battery charge thresholds (75% start, 80% stop) strictly on hardware supporting ThinkPad/compatible charge controllers.

---

## 7. Developer Toolchains & Sandboxes

- **`alien-sandbox <env>`**: Launches isolated rootless development environments (e.g. `node20`, `python312`, `rust`, `go`) using Podman or Distrobox without altering the host Debian base system.
- **`dev.slice` Isolation**: Dev terminals and containers run sandboxed from the primary graphical session.

---

## 8. Media Architecture & Hardware Video Acceleration

- **PipeWire Audio**: Managed with real-time priority via `rtkit`. Configured via `alien-audio-profile` with three distinct profiles:
  - `desktop`: Balanced 48kHz / 1024 quantum for everyday multimedia.
  - `low-latency`: 48kHz / 128 quantum for audio monitoring and virtual instruments.
  - `pro-audio`: 96kHz / 64 quantum for studio audio production.
- **Hardware Acceleration**:
  - `alien-gpu-check`: Probes DRM cards, Mesa GL, VA-API drivers (`vainfo`), and Vulkan ICD loaders (`vulkaninfo`).
  - Pre-configured `mpv` (`/etc/mpv/mpv.conf`) with `hwdec=auto-safe`.
  - Brave browser hardware acceleration flags pre-populated in `/etc/brave/flags.conf`.

---

## 9. Safety Nets & System Diagnostics

- **`alien-pkg`**: Unified front-door CLI for package discovery and tiered recommendations:
  - `--system`: Native Debian APT packages.
  - `--layer`: Modular squashfs add-on layers.
  - `--flatpak`: Sandboxed desktop applications.
  - `--sandbox`: Ephemeral developer containers.
  - `alien-pkg suggest <app>`: Advises the optimal installation tier.
- **`alien-guard`**: Interactive terminal shell hook warning before high-risk commands (`rm -rf /`, `dd of=/dev/sdX`, `mkfs`, unverified `curl | sh`).
- **`alien-doctor`**: Unified diagnostic tool validating boot assessment counters, ESP status, Btrfs subvolumes, zram health, audio profiles, and systemd failed units.
