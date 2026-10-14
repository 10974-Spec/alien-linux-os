# Alien OS Wallpaper Pipeline — Resumption Document

## Current Goal
Ship all 11 wallpapers from `branding-assets/bg/` into the Alien Lite ISO with `panel_3_1` as default, rendered offline via an idempotent pipeline, packaged as `alien-wallpapers` deb package, configured in pcmanfm-qt, proven in QEMU.

## Current Checkpoint
- **Phase 0:** ✅ Complete. State preserved in `recovery/20261013-2045`.
- **Phase 1:** ✅ Complete. `make wallpapers` operational, 13 PNGs in `branding/generated/wallpapers/`, inventory and contact sheet generated.
- **Phase 2:** ✅ Complete. `alien-wallpapers.deb` (15.3 MB) in `packages/` and `layers/shared/packages.chroot/`. `lxqt-defaults.sh` updated to `/usr/share/backgrounds/alien/default.png` with `WallpaperMode=zoom`. Gate: `make check-wallpapers` passes (5 checks green).
- **Phase 3:** ✅ Complete. `alien-wallpaper-migrate.deb` built and in `packages/` + `layers/shared/packages.chroot/`. Migration script tested (5/5). XDG autostart installed.
- **Phase 4:** ✅ Complete. "Change Wallpaper" menu entry (`alien-change-wallpaper.desktop`) ships in migration package. Slideshow is available in pcmanfm-qt but left OFF.
- **Phase 5:** ⏳ NEXT. QEMU proof required. No ISO has been built with the new packages yet.
- **Phase 6:** Skipped until Phase 5 complete (Full edition not tested in this session).
- **Phase 7:** Final report pending.

## Key File Locations
| File | Purpose |
|---|---|
| `packages/alien-wallpapers.deb` | Main wallpaper package (15.3 MB, 11 images) |
| `packages/alien-wallpaper-migrate.deb` | Migration + menu entry package |
| `layers/shared/packages.chroot/alien-wallpapers.deb` | Live-build integration |
| `layers/shared/packages.chroot/alien-wallpaper-migrate.deb` | Live-build integration |
| `branding/generated/wallpapers/` | Pre-rendered PNGs (source for .deb) |
| `branding/wallpapers.yaml` | Edit to rename wallpapers or change default |
| `branding/build-wallpapers.py` | Offline render pipeline (`make wallpapers`) |
| `build/assemble.d/lxqt-defaults.sh` | pcmanfm-qt config (now uses alien/default.png, zoom) |
| `tests/check-wallpapers-gate.py` | Gate check script (`make check-wallpapers`) |
| `tests/run-wallpaper-migrate-tests.sh` | Migration unit tests (5/5 pass) |
| `docs/WALLPAPERS-INVENTORY.md` | Full inventory and format rationale |
| `docs/ship-proof/wallpapers/contact-sheet.png` | Visual proof contact sheet |

## How to Resume
```bash
git status
cat docs/RESUME.md
cat docs/WORK-LOG.md
make check-wallpapers           # Should pass immediately (5 green checks)
bash tests/run-wallpaper-migrate-tests.sh   # Should pass (5 tests)
# Then build the ISO:
./build/build.sh lite
make test-qemu
```

## What's Still Needed (Phase 5)
1. Build the ISO: `./build/build.sh lite` (needs Docker/Podman, may need network on first run)
2. Boot in QEMU and capture screenshots proving:
   - Default wallpaper is panel_3_1 (Alien-Default.png)
   - All 11 wallpapers visible in the chooser with thumbnails
   - Switching wallpapers works
   - Fresh boot returns to default
   - Three resolutions (16:9, 16:10, 4:3) with fill/zoom working
3. Run VM-internal checks: `ls /usr/share/backgrounds/alien/`, `dpkg -s alien-wallpapers`
4. Report ISO size and RAM delta

## Login/GRUB/Plymouth Legibility Note
- `panel_3_1` is a dark image. The current Alien logo uses black outlines.
- **Likely issue:** Black-outlined logo on dark background will be nearly invisible.
- **Not changed in this task** — findings noted here, no action taken.
- To address later: add white fill or glow to the logo, or place a semi-transparent plate behind it.
- Prepared derivatives can be generated from `branding/generated/` when ready.
