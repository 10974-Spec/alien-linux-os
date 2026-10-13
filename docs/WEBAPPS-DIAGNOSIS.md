# Web Applications & Social Apps Diagnosis Report

**Document:** `docs/WEBAPPS-DIAGNOSIS.md`  
**Apps Tested:** WhatsApp, Instagram, TikTok, YouTube, Spotify, Telegram  
**Date:** 2026-10-11  

---

## 1. Executive Summary

Forensic inspection of the baseline Alien Lite ISO demonstrated why pinned social applications failed to launch:

1. **Brave Browser Missing from ISO:** The desktop entries executed `brave-browser --app="..."`. Because Brave was not installed in the ISO (missing APT repository, missing GPG key, missing from package list), all executions failed immediately with `brave-browser: command not found` (exit code 127).
2. **Shared Profile & Sandbox Collisions:** In the legacy `webapps.sh`, all apps invoked `brave-browser` with generic arguments, sharing the default user data directory. This caused window grouping collisions and lock contention.
3. **Missing Offline & DRM Handling:** When booted in an offline VM, apps threw unhandled Chromium network errors without explaining why the page could not be loaded. Spotify additionally requires Widevine DRM, which cannot be pre-shipped due to licensing constraints.
4. **Window Class Inconsistencies:** The panel launcher looked for specific window classes that did not match what standard Brave launched with, causing the LXQt taskbar to group webapps incorrectly under a generic browser icon.

---

## 2. Reproduction and Failure Matrix

| Application | Exec Target in Baseline ISO | Exit Code | Stderr / Observed Behavior | Root Cause |
|---|---|---|---|---|
| **WhatsApp** | `brave-browser --app="https://web.whatsapp.com"` | 127 | `command not found: brave-browser` | Browser not in Lite ISO |
| **Instagram** | `brave-browser --app="https://www.instagram.com"` | 127 | `command not found: brave-browser` | Browser not in Lite ISO |
| **TikTok** | `brave-browser --app="https://www.tiktok.com"` | 127 | `command not found: brave-browser` | Browser not in Lite ISO |
| **YouTube** | `brave-browser --app="https://www.youtube.com"` | 127 | `command not found: brave-browser` | Browser not in Lite ISO |
| **Spotify** | `brave-browser --app="https://open.spotify.com"` | 127 | `command not found: brave-browser` | Browser missing + Widevine DRM missing |
| **Telegram** | `/usr/share/applications/telegramdesktop.desktop` | 127 | File does not exist / package missing | Target name mismatch (`telegram-desktop`) |

---

## 3. Architecture & Remediation

To resolve all failure modes permanently:

1. **Brave Repository & GPG Key Pinning:**
   - Added verified Brave GPG keyring to `layers/shared/keyrings/brave-browser-archive-keyring.gpg`
   - Configured `layers/shared/archives/brave.list.chroot` with `[signed-by=...]` pinning
   - Added `brave-browser` to `layers/shared/package-lists/browsers.list.chroot`
2. **Dedicated Launcher (`alien-webapp`):**
   - Created `/usr/bin/alien-webapp <app-id>`
   - Isolated profiles per application under `~/.local/share/alien/webapps/<id>/`
   - Explicit `--class` and `--name` ensuring distinct panel icons and single task per window
   - Automatic GPU / QEMU detection: applies `--disable-gpu --use-gl=swiftshader` only when no GPU is present
   - User-friendly network pre-check dialog when offline
   - Strict security guarantee: **never** passes `--no-sandbox` or disables web security; relies on unprivileged user namespaces
3. **Spotify DRM Helper (`alien-enable-drm`):**
   - Created `/usr/bin/alien-enable-drm` explaining Widevine licensing and guiding the user to enable it via Brave settings
4. **Desktop Entry Generator (`webapps.sh`):**
   - Rewrote `build/assemble.d/webapps.sh` to generate desktop files pointing to `alien-webapp <id>`
   - Validated against freedesktop specifications and `desktop-file-validate`.
