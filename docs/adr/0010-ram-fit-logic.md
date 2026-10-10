# ADR 0010: Automatic RAM-Fit Logic for Live Boot

## Status
Accepted

## Context
In Puppy Linux and similar live distributions, copying the entire squashfs filesystem into RAM (`toram`) yields near-instant application launch times and frees the USB flash drive for removal.

However, unconditionally setting `toram` on systems with low physical RAM (e.g., 1 GB or 2 GB systems) causes the kernel out-of-memory killer to trigger during early userspace or leads to an immediate kernel panic when mounting the root filesystem.

## Decision
1. **Dynamic RAM Assessment (`alien.toram=auto`)**:
   - Instead of static unconditional `toram`, Alien OS implements dynamic RAM evaluation via `/etc/initramfs-tools/scripts/live-premount/alien-toram`.
   - Before mounting root, the script inspects `/proc/meminfo` (`MemTotal`).
   - Formula:
     `RAM >= (Compressed Image Size x 1.5) + 512 MB Headroom`
     For an image of ~2.0 GB, minimum required RAM is 3,500 MB (~3.5 GB).
2. **Behavior**:
   - If `MemTotal >= 3500 MB`: Enables `TORAM=yes`, copying the root squashfs to RAM.
   - If `MemTotal < 3500 MB`: Leaves `TORAM` unset; boots directly from boot media using the Linux page cache.
3. **User Overrides**:
   - Menu entries explicitly providing "Copy to RAM" (`toram`) or "Normal Live Boot" remain selectable in GRUB for users who wish to manually force a specific mode.

## Consequences
- 1 GB and 2 GB machines boot safely without crashing or hanging.
- 4 GB and 8 GB+ machines automatically enjoy lightning-fast RAM-resident performance and ejectable media.
- Preserves full compatibility with persistence partitions (`persistence`).
