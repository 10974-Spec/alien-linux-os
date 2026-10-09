# ADR 0004: Add-on Layers

## Decision
Use `systemd-sysext` or `squashfs` layers for add-on applications.

## Rationale
To keep the base system immutable and lean, large software stacks (e.g., developer tools) are shipped as separate compressed layers that can be loaded dynamically.
