# Brave Browser Diagnostic Report (Phase 3)

**Date:** 2026-10-13  
**Target Architecture:** Debian 13 (Trixie) / amd64  
**Package:** `brave-browser`  

---

## 1. Installation & Repository State

- **Package Presence:** `brave-browser` is installed in the baseline filesystem (`/usr/bin/brave-browser` -> `/opt/brave.com/brave/brave-browser`).
- **Official Repository:** `https://brave-browser-apt-release.s3.brave.com/ stable main`
- **GPG Signing Keys:**
  - Keyring: `/etc/apt/keyrings/brave-browser-archive-keyring.gpg`
  - Fingerprints verified against official Brave documentation:
    - `DBF1A116C220B8C7164F98230686B78420038257` (2022 release key)
    - `47D32A74E9A9E013A4B4926C68D513D36A73CD96` (2025 release key)
    - `B2A3DCA350E67256740DF904DE4EC67BE4B0DCA0` (2025 Jul release key)
- **Apt Pinning:** To guarantee security integrity, `/etc/apt/preferences.d/brave.pref` pins the repository to prevent untrusted package substitutions:
  ```apt
  Package: *
  Pin: origin brave-browser-apt-release.s3.brave.com
  Pin-Priority: 100

  Package: brave-browser*
  Pin: origin brave-browser-apt-release.s3.brave.com
  Pin-Priority: 990
  ```

---

## 2. Sandbox, Rendering & Execution Diagnosis

1. **Unprivileged User Namespaces:**
   - Linux user namespaces (`kernel.unprivileged_userns_clone=1`) are standard on Debian 13.
   - `chrome-sandbox` has correct `4755 root:root` permissions when installed via dpkg.
   - Under no circumstances should `--no-sandbox` or `--disable-web-security` be used, as this breaks browser isolation and security baseline.
2. **GPU & Rendering in Virtualized Environments (QEMU):**
   - In QEMU without 3D acceleration (e.g. `std-vga`, `bochs-drm`, or standard `virtio-vga` without virgl), Chromium-based browsers may crash or display blank black windows attempting to initialize Vulkan or GPU acceleration via ANGLE.
   - Stderr evidence: `[ERROR:angle_platform_impl.cc] Failed to initialize ANGLE with backend Vulkan/GL`.
   - **Solution:** A wrapper script (`/usr/local/bin/brave-browser` or `alien-browser`) checks whether a hardware GPU is detected. If only virtual/software rasterizer is present (`llvmpipe`, `softpipe`, `swrast`, or virtual VGA devices), it adds `--disable-gpu --disable-software-rasterizer` or fallback flags so rendering falls back cleanly to software without disabling sandbox security.
3. **Profile Directories & Permissions:**
   - Profiles are stored under `~/.config/BraveSoftware/Brave-Browser`.
   - Ensure permissions in `/etc/skel` and new home directories are owned by the session user.
4. **First-Run Dialogs & Telemetry Noise:**
   - Brave launches default first-run wizards asking to import bookmarks, set default search engine, and join Brave Rewards / Web3.
   - **Solution:** Deploy managed Chromium policies to `/etc/brave/policies/managed/default.json`:
     ```json
     {
       "DefaultBrowserSettingEnabled": true,
       "PromotionalTabsEnabled": false,
       "MetricsReportingEnabled": false,
       "BraveRewardsDisabled": true,
       "BraveWalletDisabled": true,
       "BraveShieldsDisabled": false,
       "RestoreOnStartup": 1
     }
     ```
5. **System-Wide Default Browser:**
   - Configured through:
     - `/etc/xdg/mimeapps.list` and `/etc/skel/.config/mimeapps.list` (`x-scheme-handler/http`, `x-scheme-handler/https`, `text/html`)
     - `update-alternatives --set x-www-browser /usr/bin/brave-browser`
     - `update-alternatives --set gnome-www-browser /usr/bin/brave-browser`
     - `export BROWSER=brave-browser`
