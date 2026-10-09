# Puppy Linux Parity Report

This document maps the features that make Puppy Linux special to their implementations in Alien OS.

## Intentional Differences
- **Root User:** Puppy runs as `root` by default to avoid permission friction. Alien runs as a normal user (`alien`) and uses `polkit` to elevate privileges for specific tools. This maintains security and follows modern best practices.
- **32-Bit Support:** Puppy often offers 32-bit versions for very old hardware. Debian 13 (Trixie) no longer focuses on 32-bit, and building a 32-bit ISO via live-build is out of scope. Alien is 64-bit only.

## Feature Parity Table

| Puppy Feature | Alien Status | Alien Tool / Setting | Verification | Source Link |
| --- | --- | --- | --- | --- |
| Run entirely from RAM ("copy to RAM") | Equivalent | `alien.toram` boot parameter mapped to `toram` | QEMU boot test with `toram` | [Puppy Boot Options](https://puppylinux-woof-ce.github.io/) |
| Save session / persistence | Equivalent | `persistence` boot parameter + `alien-usb-installer` | QEMU persistence reboot test | [Puppy Persistence](https://puppylinux.com/) |
| Add-on layers (SFS) | Equivalent | `systemd-sysext` or `live-boot` squashfs layers | `alien-layers` tests | [Puppy SFS](https://puppylinux-woof-ce.github.io/) |
| Frugal install | Equivalent | Grub loopback boot + `alien-usb-installer` | QEMU virtual disk install | [Frugal Install](https://puppylinux.com/) |
| Remaster | Equivalent | `mksquashfs` + `xorriso` pipeline | `alien-remaster` tool | [Remaster](https://puppylinux.com/) |
| Puppy Universal Installer | Equivalent | `alien-usb-installer` | USB virtual disk write test | [Installer](https://puppylinux-woof-ce.github.io/) |
| Puppy Control Panel | Equivalent | Alien Control Hub (`alien-control`) | Hub layout verification | [Control Panel](https://puppylinux.com/) |
| Quick Setup Wizard | Equivalent | First-run setup wizard (`alien-quick-setup`) | QEMU boot interaction test | [Quick Setup](https://puppylinux.com/) |
| Network helper | Equivalent | NetworkManager + Firmware detector | QEMU interface test | [Network Wizard](https://puppylinux.com/) |
| Display Wizard (Xorg wizard) | Equivalent | Alien Display Wizard | Revert mechanics test | [Xorg Wizard](https://puppylinux.com/) |
| Drive mounting tray (Pmount) | Equivalent | LXQt mount plugin | Panel mount verification | [Pmount](https://puppylinux.com/) |
| Startup Manager (BootManager) | Equivalent | Alien Startup Manager | Service toggling test | [BootManager](https://puppylinux.com/) |
| Simple backup and restore | Equivalent | Rsync-based backup tool | Dry-run rsync verification | [Backup](https://puppylinux.com/) |
| Friendly boot options | Equivalent | Custom GRUB entries | QEMU boot menu test | [Boot Parameters](https://puppylinux.com/) |
| Package Handling (AppImage, Quickpet) | Equivalent | `alien-store`, apt, AppImage | Alien Store verification | [Quickpet](https://puppylinux.com/) |
