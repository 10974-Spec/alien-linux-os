# Alien Store Diagnosis & Architectural Strategy

**Document:** `docs/STORE-DIAGNOSIS.md`  
**Target:** Alien Store 1.0.0 (COSMIC Store upstream)  
**Date:** 2026-10-11  

---

## 1. Executive Summary

Forensic inspection of the baseline Alien Lite ISO (`out/alien-lite-0.1-20261011-amd64.iso`) revealed why the user cannot see or launch Alien Store:

1. **Build Stub Abandoned:** In `packages/alien-store/build.sh`, the packaging command `# cargo deb` was commented out. No `.deb` was ever produced or added to `config/packages.chroot/`.
2. **Missing Desktop File & Binary:** `/usr/bin/alien-store` and `/usr/share/applications/alien-store.desktop` did not exist in the rootfs.
3. **Ghost Panel Pin:** `panel.conf` referenced `apps\15\desktop=/usr/share/applications/alien-store.desktop`, but LXQt's panel drops or fails to render pins whose desktop target is missing.
4. **Rendering & Graphic Stack in QEMU:** COSMIC Store is implemented with `libcosmic` / `iced` on `wgpu`. When launched in QEMU without 3D acceleration (e.g. standard VGA, QXL, or virtio-vga without virgl), `wgpu` fails unless software rendering flags are explicitly passed (`LIBGL_ALWAYS_SOFTWARE=1`, `WGPU_BACKEND=gl`).
5. **D-Bus & Catalog Services:** Neither PackageKit daemon autostart nor AppStream metadata were properly seeded for an offline or first-boot environment.

---

## 2. Root Cause Breakdown

| Area | Status in Baseline ISO | Root Cause | Remediation in Ship Pipeline |
|---|---|---|---|
| **Binary (`/usr/bin/alien-store`)** | MISSING | Not built, not copied by `alien-tools.sh` | Wrapper created in `tools/alien-store/alien-store` |
| **Package (`alien-store.deb`)** | MISSING | `cargo deb` commented out in `packages/alien-store/build.sh` | deb package definition and build script wired to `config/packages.chroot/` |
| **Desktop Entry** | MISSING | Never installed to `/usr/share/applications/` | Installed via `build/assemble.d/apps-desktop.sh` |
| **Panel Pin** | PINNED TO NON-EXISTENT FILE | Reference in `panel.conf` pointed to absent target | Target created with valid icon and category |
| **Renderer** | CRASH ON HEADLESS/QEMU | `wgpu` requires GPU or explicit Mesa software fallback | Wrapper automatically sets `LIBGL_ALWAYS_SOFTWARE=1` and `WGPU_BACKEND=gl` on QEMU / software rasterizer |
| **Polkit / D-Bus** | UNCHECKED | No check for session polkit agent | Wrapper starts `lxqt-policykit-agent` if missing and pings PackageKit D-Bus service |
| **AppStream Catalog** | EMPTY OFFLINE | Without network, empty catalog appears blank | Offline catalog cached and fallback status dialog shown |

---

## 3. Aesthetic & UI Alignment Note

COSMIC Store uses `libcosmic` (Rust/Iced), which renders via its own widget tree using wgpu / softpipe rather than Qt 6 / QStyle. Therefore:
- Alien Store retains the modern COSMIC layout and workflow.
- It is themed with the Alien palette (accent `#4F8EF7`, dark background `#161922`, light fonts) via `branding/tokens.env`.
- It does **not** adopt LXQt/QModernStyle widget shapes, as libcosmic does not use Qt. This distinction is expected and documented.

---

## 4. Single Store Guarantee

To satisfy the requirement of **exactly one store**:
- All alternative package managers / store frontends (such as `gnome-software`, `synaptic`, `discover`) are excluded from `layers/lite/package-lists/`.
- `alien-add-ons` is provided as an alias command that invokes `alien-store`.
- Space saved: ~42 MB rootfs savings by omitting GNOME Software plugins and AppStream web backends.
