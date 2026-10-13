# Alien OS Wallpaper Pipeline — Resumption Document

## Current Goal
Ship all 11 wallpapers from `branding-assets/bg/` into the Alien Lite ISO with `panel_3_1` as default, rendered offline via an idempotent pipeline, packaged as `alien-wallpapers` deb package, configured in pcmanfm-qt, proven in QEMU.

## Current Checkpoint
- **Phase 0:** Completed. State preserved in `recovery/20261013-2045`. Partial renders cleared.
- **Phase 1:** In Progress. Wallpaper inspection, format evaluation, rendering pipeline creation.

## How to Resume
Run:
```bash
git status
cat docs/RESUME.md
make wallpapers
```
