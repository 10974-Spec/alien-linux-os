# Alien Player: Architectural Specification & Feature Matrix

**Document:** `docs/PLAYER-FEATURES.md`  
**Application:** Alien Player (`alien-player`)  
**Backend:** mpv / libmpv (LGPL-2.1+) with Qt UI Integration  
**Date:** 2026-10-11  

---

## 1. Architectural Strategy & ADR Summary

### Decision
For Alien OS Lite, `alien-player` leverages the high-performance `mpv` engine (LGPL-2.1+) with dedicated Alien UI bindings, custom configuration storage (`~/.config/alien/player`), and IPC socket control, rather than shipping the full VLC desktop application (which carries the cone icon and higher resource footprint).

### Key Architectural Commitments
1. **LGPL Compliance:** Clean separation from GPL components; no proprietary codecs bundled.
2. **Resource Efficiency:** Zero idle memory footprint when idle; under 45 MB RAM during video playback.
3. **Safety:** Handles malformed/corrupted streams without crashing; runs under an AppArmor sandbox profile.

---

## 2. Feature Slices & Implementation Status

| Slice | Feature Set | Status in v1.0 | Implementation & CLI / Hotkey |
|---|---|---|---|
| **P1: Queue & Playlists** | Shuffle, repeat, M3U/PLS loading, recent files, resume position per file | **Done** | `--save-position-on-quit`, `--watch-later-directory`, playlist drag-and-drop |
| **P2: Playback Control** | Speed 0.25x–4x, frame-by-frame step, A-B loop, jump to time, volume up to 200% | **Done** | `[` / `]` for speed, `.` for frame step, `l` for A-B loop, volume warning at 130%+ |
| **P3: Audio Processing** | Audio track selector, audio delay adjustment, 10-band equalizer presets | **Done** | `#` for track cycle, `Ctrl++` / `Ctrl+-` for audio delay |
| **P4: Subtitles & Video** | Subtitle tracks, external SRT/ASS, delay, styling, aspect ratio, snapshot | **Done** | `j` / `J` for sub cycle, `s` for snapshot (PNG saved to `~/Pictures/Screenshots`) |
| **P5: Media Info & Tools** | Media inspector, bookmarks, stream capture | **Done** | `i` / `I` for real-time codec and bitrate info overlay |
| **P6: Network Streaming** | HTTP, HLS, DASH, RTSP, UDP network playback | **Done** | Full URL argument support; libdvdcss omitted due to legal restrictions |
| **P7: Integration & Desktop** | VLC-compatible shortcuts, hardware VAAPI decoding with soft fallback, MPRIS2 | **Done** | MPRIS2 D-Bus interface active for lockscreen and media keys (`playerctl`) |

---

## 3. QEMU vs. Bare-Metal Testing Boundary

- **Tested in QEMU:** Software rasterization, synthetic test video playback, position retention, CLI argument parsing, window opening and closing, audio dummy output.
- **Requires Bare-Metal Verification:** Hardware VAAPI/NVDEC decoding on discrete GPUs, physical HDMI/DisplayPort audio passthrough, optical disc drives.
