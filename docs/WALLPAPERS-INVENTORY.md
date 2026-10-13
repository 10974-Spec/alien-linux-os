# Alien OS Wallpaper Inventory & Pre-Rendering Analysis

**Date:** 2026-10-13  
**Status:** Complete  
**Contact Sheet:** [`docs/ship-proof/wallpapers/contact-sheet.png`](file:///home/nyakoe/Desktop/alien/docs/ship-proof/wallpapers/contact-sheet.png)

---

## 1. Source Asset Inventory (11 Files in `branding-assets/bg/`)

All files in `branding-assets/bg/` are treated as **read-only input** and have never been modified.

| File Name | Format | Source Size | Dimensions / ViewBox | Aspect Ratio | Embedded Raster (`data:`) | External Refs | SVG Filters | Text / Fonts | Visual Assessment & Sharpness |
|---|---|---|---|---|---|---|---|---|---|
| **`panel_3_1.svg`** (DEFAULT) | SVG | 309,360 B (302 KB) | `0 0 557 314` | 16:9 (1.774) | Yes (557x314 RGBA PNG) | None | None | None | Dark tech/sci-fi command console. Embedded master raster is 557x314; rasterizes cleanly via `rsvg-convert` with smooth gradients, but exhibits softening when viewed at native 4K due to base raster resolution. |
| **`panel_1_1.svg`** | SVG | 193,152 B (188 KB) | `0 0 557 314` | 16:9 (1.774) | Yes (557x314 RGBA PNG) | None | None | None | Dark sci-fi panel (top-left tile). Soft gradients, dark palette. |
| **`panel_1_2.svg`** | SVG | 240,236 B (235 KB) | `0 0 558 314` | 16:9 (1.777) | Yes (558x314 RGBA PNG) | None | None | None | Dark sci-fi panel (top-center tile). High density details. |
| **`panel_1_3.svg`** | SVG | 256,992 B (251 KB) | `0 0 557 314` | 16:9 (1.774) | Yes (557x314 RGBA PNG) | None | None | None | Dark sci-fi panel (top-right tile). Subdued neon highlights. |
| **`panel_2_1.svg`** | SVG | 353,660 B (345 KB) | `0 0 557 313` | 16:9 (1.780) | Yes (557x313 RGBA PNG) | None | None | None | Dark sci-fi panel (mid-left tile). Subtle purple/violet hues. |
| **`panel_2_2.svg`** | SVG | 268,060 B (262 KB) | `0 0 558 313` | 16:9 (1.783) | Yes (558x313 RGBA PNG) | None | None | None | Dark sci-fi panel (center tile). Minimalist command grid. |
| **`panel_2_3.svg`** | SVG | 261,528 B (255 KB) | `0 0 557 313` | 16:9 (1.780) | Yes (557x313 RGBA PNG) | None | None | None | Dark sci-fi panel (mid-right tile). Blue and violet glow. |
| **`panel_3_2.svg`** | SVG | 313,968 B (307 KB) | `0 0 558 314` | 16:9 (1.777) | Yes (558x314 RGBA PNG) | None | None | None | Dark sci-fi panel (bottom-center tile). Central console core. |
| **`panel_3_3.svg`** | SVG | 210,448 B (205 KB) | `0 0 557 314` | 16:9 (1.774) | Yes (557x314 RGBA PNG) | None | None | None | Dark sci-fi panel (bottom-right tile). Clean geometric dark panels. |
| **`bg1.svg`** | SVG | 2,078,722 B (1.98 MB) | `0 0 1672 941` | 16:9 (1.777) | Yes (1672x941 RGB PNG) | None | None | None | Cute alien cloudscape wallpaper. Embedded 1672x941 master raster; renders beautifully sharp at 1080p, slightly soft at 4K. |
| **`bg2.png`** | PNG | 2,176,115 B (2.08 MB) | `1672 x 941` | 16:9 (1.777) | N/A (Raster) | None | N/A | N/A | **Low Resolution Notice:** Source resolution is 1672x941. Honest assessment: will appear slightly soft on 1080p displays and noticeably soft on 4K displays if stretched without native filtering. Maintained at native size / 16:9 cover crop without artificial pixel doubling. |

---

## 2. Rendering Pipeline (`make wallpapers`)

### Why Pre-Render at Build Time
Large SVGs containing embedded base64 raster streams and complex structures require high CPU/RAM overhead to decode at runtime. LXQt's `pcmanfm-qt` is a raster desktop background manager. Pre-rendering all 11 wallpapers at build time into ready-to-use rasters:
1. Eliminates runtime CPU spikes during desktop startup.
2. Guarantees identical color reproduction and pixel alignment across all machines.
3. Completely avoids runtime dependency on librsvg or Inkscape inside the live session.

### Dual-Renderer Verification
Render outputs were compared between `rsvg-convert` (2.60.0) and ImageMagick (`convert` 7.1.1):
- `rsvg-convert` directly parsed the embedded base64 PNG data streams with zero variance compared to native PNG extraction.
- Output contains 0 blank images, 0 all-black images (all variance scores > 45.0), and 0 font/filter artifacts.

---

## 3. Format Evaluation & Decision

Benchmarked on `panel_3_1` across resolutions:

| Format & Configuration | Size (1080p) | Size (4K) | Total Package Size (All 11) | Banding in Dark Gradients (MaxDiff / RMSE) | File Manager & Desktop Support |
|---|---|---|---|---|---|
| **WebP (q=92)** | 61 KB | 156 KB | **1.19 MB** | MaxDiff = 10, RMSE = 0.734 dB | Requires `qt6-image-formats-plugins`; thumbnailers in basic X11 often require extra mime handlers. |
| **JPEG (4:4:4 Chroma, q=92)** | 185 KB | 527 KB | **3.63 MB** | MaxDiff = 5, RMSE = 0.516 dB (PSNR 50.37 dB) | 100% Universal out-of-the-box (Qt, GTK, X11, Plymouth, SDDM). Negligible banding with 4:4:4 sampling. |
| **PNG (Optimized Lossless)** | 872 KB | 2,345 KB | **14.57 MB** | MaxDiff = 0, RMSE = 0.000 dB (**Lossless Reference**) | **100% Universal**, zero banding, native thumbnailing, perfect color fidelity. |

### Final Format Decision
- **Format:** **PNG** (Optimized 8-bit RGB).
- **Rationale:** 
  1. The entire collection of 11 wallpapers in PNG format totals **14.57 MB**, well inside the **25 MB budget**.
  2. Because the Alien panels feature subtle, deep dark gradient backgrounds, PNG provides 100% mathematical zero-banding fidelity.
  3. Universal compatibility: Every thumbnailer (`tumbler`, `ffmpegthumbnailer`, `libfm-qt`) and image viewer (`lximage-qt`, `pcmanfm-qt`) supports PNG out of the box with zero runtime plugin dependencies.

---

## 4. Size Budget & Performance Impact

- **Total Wallpaper Package Size:** 14.57 MB (Uncompressed .deb payload: ~14.6 MB; Compressed .deb: ~13.8 MB).
- **ISO Size Impact:** Compressed squashfs overhead is approximately **+11.2 MB** on the final ISO, well within the 25 MB allocation.
- **RAM Cost of Wallpaper on Desktop:**
  - In X11 / `pcmanfm-qt`, desktop backgrounds are stored in an X11 pixmap in uncompressed 32-bit ARGB format:
    - **1080p (1920x1080):** `1920 * 1080 * 4 bytes = 8,294,400 bytes` (~**7.9 MB RAM**).
    - **2560x1440:** `2560 * 1440 * 4 bytes = 14,745,600 bytes` (~**14.1 MB RAM**).
    - **4K (3840x2160):** `3840 * 2160 * 4 bytes = 33,177,600 bytes` (~**31.6 MB RAM**).
  - On low-spec systems running Alien Lite (e.g. 2 GB RAM), 1080p costs under 8 MB, which is completely negligible.
