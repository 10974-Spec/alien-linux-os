# Alien OS Wallpaper Pipeline — Resumption Document

## Current Goal
Ship all 11 wallpapers from `branding-assets/bg/` into the Alien Lite ISO with `panel_3_1` as default, rendered offline via an idempotent pipeline, packaged as `alien-wallpapers` deb package, configured in pcmanfm-qt, proven in QEMU.

## Current Checkpoint
- **Phase 0:** Completed. State preserved in `recovery/20261013-2045`.
- **Phase 1:** Completed. `make wallpapers` operational, 11 files rendered to `branding/generated/wallpapers/`, inventory and contact sheet generated.
- **Phase 2:** In Progress. Creating Debian package `packages/alien-wallpapers`.

## How to Resume
Run:
```bash
git status
cat docs/RESUME.md
make wallpapers
cd packages && ./build-packages.sh
```
