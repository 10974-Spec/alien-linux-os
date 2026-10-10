# ADR 0006: Btrfs Default Layout and Snapper Snapshot Integration

## Status
Accepted

## Context
Traditional Linux desktop installations on ext4 lack atomic state rollbacks and instant volume snapshots. When software updates or package removals corrupt core libraries, recovery often requires live USB rescue or manual chroot intervention.
Alien OS requires an unbrickable installed-system layout that provides:
1. Instant atomic snapshots before and after package manager transactions (`apt`).
2. Bootable snapshots directly accessible from the GRUB boot menu.
3. Separation between system state (`@`) and user personal data (`@home`) so rolling back the system never regresses user documents or downloads.
4. Clean exclusions for high-churn runtime logs (`@var_log`) and package caches (`@var_cache`) to prevent snapshot bloat.

## Decision
1. **Calamares Btrfs Subvolume Structure**: Calamares installs Btrfs by default using the following subvolume schema:
   - `@` -> `/` (Root system)
   - `@home` -> `/home` (User data)
   - `@snapshots` -> `/.snapshots` (Snapper snapshots)
   - `@var_log` -> `/var/log` (System logs, excluded from system rollbacks)
   - `@var_cache` -> `/var/cache` (APT and application caches)
2. **Mount Options**: Mount subvolumes with:
   `noatime,compress=zstd:1,space_cache=v2,discard=async`
3. **Boot Directory**: `/boot` resides inside `@` (root subvolume) so that kernel images and initramfs versions are snapshot in sync with root filesystem libraries and modules.
4. **Snapper Integration**:
   - Automatic pre/post APT hook installed at `/etc/apt/apt.conf.d/80-alien-snapper`.
   - Dedicated snapshot GRUB generator `/etc/grub.d/41_snapshots-btrfs` parses Snapper snapshots and renders them under the GRUB "Snapshots & Rollbacks" submenu.
5. **Alternative Filesystems**: Users may still select `ext4` in Calamares, but an explicit warning is displayed that automatic transaction rollback and GRUB snapshot booting are unavailable.

## Consequences
- System rollbacks via `alien-snapshot rollback <ID>` or `alien-recover` are instantaneous and atomic.
- User files in `/home` remain untouched when rolling back root.
- Disk usage overhead is minimal due to Btrfs copy-on-write (CoW) and zstd:1 transparent compression.
- Ext4 remains supported for users on legacy setups.
