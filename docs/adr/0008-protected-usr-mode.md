# ADR 0008: Protected Mode (Read-Only /usr)

## Status
Accepted

## Context
Desktop distributions often suffer from accidental system file modifications, rogue build scripts modifying system binaries, or malware tampering with `/usr`. An immutable or read-only `/usr` prevents tampering and accidental damage while preserving normal package manager operations.

However, hard-enforced immutable filesystems (like ostree or systemd-sysupdate image-based systems) break traditional Debian APT workflows, DKMS module compiling, local script installation, and traditional software development tools.

## Decision
1. **Opt-in `alien-protect`**:
   - Provide `alien-protect on`, `alien-protect off`, and `alien-protect status`.
   - Mounts `/usr` read-only (`mount -o remount,ro /usr`).
   - Maintains `/usr/local` as writable via a bind-mount so users and local scripts can install tools without altering the system core.
2. **APT / DPkg Transaction Hooks**:
   - Configure `/etc/apt/apt.conf.d/75-alien-protect` with `DPkg::Pre-Invoke` and `DPkg::Post-Invoke` hooks.
   - Automatically remounts `/usr` read-write before any package installation, upgrade, or removal.
   - Always remounts `/usr` read-only after the transaction, ensuring state restoration even if APT exits with an error or interrupt.
3. **Default Policy**:
   - Default is **OFF** out-of-the-box to preserve 100% Debian compatibility with developers, custom kernel compilation, and ad-hoc system configuration.
   - Users and administrators can toggle protection on with a single command.

## Consequences
- Accidental commands (`sudo rm -rf /usr/bin`, malicious installers) fail immediately with "Read-only file system".
- Standard `apt-get install` commands continue working seamlessly without manual unlocking.
- Zero deviation from standard Debian packaging standards.
