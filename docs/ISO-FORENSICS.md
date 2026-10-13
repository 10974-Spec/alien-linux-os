# Alien OS ISO Forensics Report (Phase 0)

**Date:** 2026-10-13  
**Target ISO:** `out/alien-lite-0.1-2bd5ae9-20261012-1256-amd64.iso`  
**Tooling:** `xorriso`, `unsquashfs`, `dpkg`, static file audits (`tools/iso-inspect.sh`)  

---

## 1. Inventory of Images and Virtual Disks

The following images and disks were found in the workspace:

| Path | Size | Timestamp | Assessment |
|---|---|---|---|
| `out/alien-lite-0.1-2bd5ae9-20261012-1256-amd64.iso` | 2.3 GB (2,450,653,184 bytes) | 2026-10-12 15:00:57 | **Newest build** — baseline for reset. |
| `out/alien-lite-0.1-20261011-amd64.iso` | 2.1 GB (2,244,476,928 bytes) | 2026-10-11 17:36:00 | Previous build. |
| `out/alien-lite-0.1-20261009-amd64.iso` | 2.0 GB (2,095,104,000 bytes) | 2026-10-09 13:57:00 | Older build. |
| `out/alien-lite-0.1-20261008-amd64.iso` | 2.0 GB (2,053,521,408 bytes) | 2026-10-08 18:57:00 | Older build. |
| `out/alien-full-0.1-20261008-amd64.iso` | 4.0 GB (4,283,338,752 bytes) | 2026-10-08 08:29:00 | Older Full edition build. |
| `out/alien-lite-0.1-amd64.iso` | 1.5 GB (1,540,489,216 bytes) | 2026-10-07 16:15:00 | Legacy build. |
| `out/alien-0.1-amd64.iso` | 4.0 GB (4,248,928,256 bytes) | 2026-10-07 13:49:00 | Initial build. |
| `vm/alien-install-30g.qcow2` | 192 KB | 2026-10-11 18:04:00 | Stale empty test disk from earlier install run. |

---

## 2. Boot Architecture Audit

- **Kernel Command Line (Live ISO):** Currently set via `lb config --bootappend-live "boot=live components quiet splash locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC hostname=alien username=alien alien.toram=auto persistence console=ttyS0"`. Lacks `loglevel=3 systemd.show_status=false vt.global_cursor_default=0` and `gfxpayload=keep`.
- **GRUB Configuration:** `build/assemble.d/boot-branding.sh` configures GRUB with `set timeout=5`, `set timeout_style=menu`, defining 6 visible top-level menu entries (`Live`, `Automated Self-Test`, `Copy to RAM`, `Persistence`, `Install`, `Safe Graphics`) plus a `Tools & Diagnostics` submenu. User requirement: A single top-level entry ("Alien Lite"), `timeout_style=hidden` with a 1-2s window (holding Shift or Esc reveals), and a single "More options" submenu.
- **Plymouth Theme Status:**
  - `plymouth` and `plymouth-themes` are installed in the squashfs.
  - Theme is configured in `/etc/plymouth/plymouthd.conf` (`Theme=alien`, `ShowDelay=0`).
  - Theme files exist in `/usr/share/plymouth/themes/alien/` (`alien.plymouth`, `alien.script`, `logo.png`).
  - **Issue:** The initramfs hook (`0050-plymouth-update.hook.chroot`) ran before Plymouth themes were fully registered or failed to pack all script module dependencies into `/boot/initrd.img`, causing Plymouth not to display during the graphical handoff.

---

## 3. Browser Audit

- **Package State:** `brave-browser` is installed (`/usr/bin/brave-browser`, Status: `install ok installed`).
- **Repository and Key:** In `layers/shared/archives/`, `brave.list.chroot` currently specifies `deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main` without `signed-by=` and lacks strict apt pinning in `/etc/apt/preferences.d/`.
- **Launch & Runtime:** Launched directly via `/usr/bin/brave-browser-stable %U` without GPU detection. In QEMU VMs lacking 3D acceleration or user namespaces configuration, Brave fails to initialize hardware rendering cleanly.
- **Policies:** Managed policy exists in `/etc/brave/policies/managed/alien-policy.json`. Needs verification against Brave official documentation to ensure all telemetry/prompts are suppressed while sandbox is strictly preserved.

---

## 4. Custom Apps & Desktop Integration Audit

- **`alien-player`:** Stub script at `/usr/bin/alien-player` wrapping `mpv` without arguments; not installed as a dpkg package. Associated with placeholder icon (`/usr/share/icons/hicolor/scalable/apps/alien-player.svg`, a plain blue SVG rectangle `#1e7cd4`).
- **`alien-viewer`:** Shell wrapper at `/usr/bin/alien-viewer` searching for image viewers; not installed via dpkg. Uses a teal SVG rectangle (`#2a9d8f`) placeholder icon.
- **`alien-notes`:** Shell wrapper at `/usr/bin/alien-notes` invoking `featherpad`; not installed via dpkg. Uses a yellow SVG rectangle (`#e9c46a`) placeholder icon.
- **Resolution:** As per prompt, remove these skeleton wrappers completely. Install genuine, mature applications from Debian 13:
  - Video Player: **VLC** (`vlc`, `vlc-plugin-base`, `vlc-plugin-qt`).
  - Image Viewer: **`lximage-qt`** (LXQt-native, lightweight, format-rich).
  - Notes: **`ghostwriter`** (Debian 13 native Markdown notes editor) or preconfigured Markdown notes workspace with FeatherPad preserved.

---

## 5. Store / Software Center Audit

- **Current State:** **0 working stores installed!**
- `alien-store` is a wrapper script that attempts to find `/usr/libexec/alien-store/alien-store-bin` or `cosmic-store`. Because `cosmic-store` was never built or packaged, `alien-store` falls back to a Zenity dialog.
- No other store (Synaptic, Discover, GNOME Software) was installed in the Lite edition.
- **Resolution:** Safety net protocol in Phase 6: verify if COSMIC Store can run reliably under X11 software rendering. If not, ship the lightest working alternative (**Synaptic** or **Discover**) as the single store, removing all stubs.

---

## 6. Social Web Apps Audit

- **Present in ISO:**
  - `alien-webapp-whatsapp-web.desktop`
  - `alien-webapp-instagram.desktop`
  - `alien-webapp-tiktok.desktop`
  - `alien-webapp-youtube.desktop`
  - `alien-webapp-spotify.desktop`
- **Machinery:** `build/assemble.d/webapps.sh`, `packages/alien-webapp/`, `/usr/bin/alien-webapp`, and panel pin entries `apps\4` through `apps\8` in `/etc/skel/.config/lxqt/panel.conf`.
- **Resolution:** Completely remove the 5 social web apps and their machinery. Retain Brave Browser and native Telegram Desktop.

---

## 7. Action Plan Mapping to User's 7 Problems

1. **Boot Splash:** Fix initramfs Plymouth generation (`plymouth-set-default-theme -R alien` and hook order) and add kernel parameters `quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0` with `gfxpayload=keep`.
2. **Simple Boot:** Configure GRUB with hidden timeout (1s), single top-level entry ("Alien Lite"), all diagnostics moved to "More options" submenu.
3. **Custom Apps:** Remove skeleton wrappers; integrate real, proven Debian 13 apps (VLC for video, `lximage-qt` for images, `ghostwriter`/Markdown notes for notes, keeping FeatherPad).
4. **COSMIC Store:** Audit COSMIC Store build; if unviable on software X11 stack, ship the lightest working store (Synaptic) per safety net rules.
5. **Brave Browser:** Install Brave with verified official GPG keyring, apt pinning, GPU-detection launch wrapper (software rasterizer fallback in QEMU), and managed policy.
6. **Social Web Apps:** Purge WhatsApp, Instagram, TikTok, YouTube, and Spotify along with `alien-webapp` launcher and DRM script; preserve Brave and native Telegram Desktop.
7. **Icons8 Colored Icons:** Replace placeholder rectangles with high-resolution colored icons (from Papirus colored set / Icons8 style) across all standard sizes (16px to 512px + scalable).
