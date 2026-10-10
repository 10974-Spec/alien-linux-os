# ADR 0007: GRUB Boot Assessment and Automatic Fallback

## Status
Accepted

## Context
A critical vulnerability in desktop Linux updates is a bad kernel update, broken proprietary GPU driver (e.g. DKMS failure), or corrupted initramfs that causes a boot hang or kernel panic before the graphical session starts. Without automated boot counting, users are faced with a black screen or blinking cursor and must manually diagnose the issue.

Alien OS requires an unbrickable boot flow where:
1. Boot attempts are tracked across reboot cycles.
2. If boot attempts exceed the limit without reaching a healthy desktop session, the system automatically falls back to the previous working kernel or last good snapshot.
3. Healthy boots reset the counter.

## Decision
1. **GRUB Attempt Counter**:
   - `/etc/grub.d/01_alien_boot_counter` manages an `alien_boot_tries` counter initialized to 3.
   - On each boot entry selection, the counter is decremented.
   - If `alien_boot_tries` reaches 0, GRUB automatically falls back to the previous kernel entry in the Advanced menu, sets `timeout_style=menu`, and enables interactive recovery.
2. **GRUB Environment Limitation on Btrfs**:
   - GRUB cannot reliably write `grubenv` directly to Btrfs subvolumes due to filesystem checksumming and CoW design constraints.
   - **UEFI Solution**: `grubenv` is stored on the FAT32 EFI System Partition (ESP) at `/boot/efi/EFI/alien/grubenv`. GRUB uses `load_env -f ($root)/EFI/alien/grubenv` and `save_env -f ($root)/EFI/alien/grubenv`.
   - **BIOS Solution**: BIOS systems lack an ESP partition. Automatic decrementing is documented as UEFI-only; on BIOS, standard `GRUB_RECORDFAIL_TIMEOUT` and recovery menu entries are provided.
3. **Health Confirmation**:
   - `alien-boot-good.service` runs after `graphical.target` and display manager startup.
   - Calls `/usr/bin/alien-boot-mark-good` which resets `alien_boot_tries=3` and sets `alien_boot_success=1`.
4. **Panic Handling**:
   - Added `panic=10` to kernel command-line defaults (`/etc/default/grub.d/50_alien.cfg`) so that kernel panics trigger an automatic reboot after 10 seconds, allowing the boot counter to decrement and trigger fallback.

## Consequences
- Systems that crash during early boot or fail to reach the desktop automatically recover on subsequent boots without requiring external rescue media.
- Clean boots remain silent and fast with `GRUB_TIMEOUT_STYLE=hidden`.
