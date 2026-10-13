# Alien OS Wallpaper Pipeline Recovery Report

**Timestamp:** 2026-10-13 20:47:00 UTC  
**Preservation Branch:** `recovery/20261013-2045`  
**Base Commit:** `d43debb` (build-tools: implement build identity and anti-stale run tooling)

---

## 1. Summary of Incident & Repository State

Prior to session interruption during wallpaper integration:
1. **Source Assets:** All 11 wallpaper assets are safely present and intact in `branding-assets/bg/`:
   - `bg1.svg` (2.0M - Cloudscape original)
   - `bg2.png` (2.1M - Neon original)
   - `panel_1_1.svg` through `panel_1_3.svg` (193KB - 256KB)
   - `panel_2_1.svg` through `panel_2_3.svg` (261KB - 353KB)
   - `panel_3_1.svg` through `panel_3_3.svg` (210KB - 313KB)
   `branding-assets/bg/` is treated as strictly read-only input.
2. **Preservation:** All uncommitted changes were captured and preserved in backup branch `recovery/20261013-2045`.
3. **Artifacts Left by Dropped Session:**
   - 9 rasterized PNG files and 9 raw SVGs were placed in `branding/generated/backgrounds/panel_*` without proper multi-resolution generation, size budget optimization, or packaging.
   - Partial modifications in `build/assemble.d/desktop-identity-branding.sh` and `build/assemble.d/lxqt-defaults.sh` attempted raw copying of panel wallpapers directly to `/usr/share/backgrounds/` rather than shipping via `alien-wallpapers` deb package.
4. **Build State & Containers:**
   - No dangling podman or docker build containers were locked.
   - Container engine: Docker is available and operational (`alien-builder:trixie` image ready).
   - Cache volume `alien-build-cache` intact.
   - Latest built ISO in `out/`: `alien-lite-20261013-1425-d43debb.iso` (2.4 GB).
5. **Lock Files / Merges:**
   - No `.orig`, `.rej`, or live-build lock files detected.

---

## 2. Items Kept vs. Redone

| Item | Action | Rationale |
|---|---|---|
| `branding-assets/bg/*` (11 files) | **KEPT (Read-Only)** | Pristine original vector/raster assets provided by user. |
| `packages/alien-store`, app desktop configs, test harnesses | **KEPT** | Preserved features from prior application work. |
| `branding/generated/backgrounds/panel_*.png` & `*.svg` | **REMOVED** | Sub-optimal 1080p-only renders (86MB total) with no budget control; raw SVGs must not ship in ISO. |
| Direct `cp` in `desktop-identity-branding.sh` | **REDONE** | Will be cleanly replaced by `alien-wallpapers` deb package adhering to standard paths. |
| LXQt desktop settings in `lxqt-defaults.sh` | **REDONE** | Will point to stable `/usr/share/backgrounds/alien/default.<ext>` symlink using verified keys (`zoom` fill mode). |

### Deletions Record
- `branding/generated/backgrounds/panel_1_1.png`
- `branding/generated/backgrounds/panel_1_2.png`
- `branding/generated/backgrounds/panel_1_3.png`
- `branding/generated/backgrounds/panel_2_1.png`
- `branding/generated/backgrounds/panel_2_2.png`
- `branding/generated/backgrounds/panel_2_3.png`
- `branding/generated/backgrounds/panel_3_1.png`
- `branding/generated/backgrounds/panel_3_2.png`
- `branding/generated/backgrounds/panel_3_3.png`
- `branding/generated/backgrounds/panel_1_1.svg`
- `branding/generated/backgrounds/panel_1_2.svg`
- `branding/generated/backgrounds/panel_1_3.svg`
- `branding/generated/backgrounds/panel_2_1.svg`
- `branding/generated/backgrounds/panel_2_2.svg`
- `branding/generated/backgrounds/panel_2_3.svg`
- `branding/generated/backgrounds/panel_3_1.svg`
- `branding/generated/backgrounds/panel_3_2.svg`
- `branding/generated/backgrounds/panel_3_3.svg`

---

## 3. Recovery Execution Plan

1. **Phase 1:** Wallpaper inventory (`docs/WALLPAPERS-INVENTORY.md`), offline pre-rendering pipeline via `make wallpapers`, format quality/size evaluation (WebP vs JPEG vs PNG), contact sheet generation.
2. **Phase 2:** Create `alien-wallpapers` deb package in `packages/alien-wallpapers` with manifest `branding/wallpapers.yaml`, shipping to `/usr/share/backgrounds/alien/` with symlinks.
3. **Phase 3:** Set default wallpaper (`panel_3_1`) in `/etc/skel` and `/etc/xdg` pcmanfm-qt configs (`WallpaperMode=zoom`), implement and unit-test `alien-wallpaper-migrate`.
4. **Phase 4:** Wallpaper picker UX improvements, "Change Wallpaper" desktop entry, slideshow validation.
5. **Phase 5:** ISO rebuild, automated QEMU gate verification, resolution proof screenshots, final measurement.
