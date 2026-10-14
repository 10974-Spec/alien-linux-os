# Alien OS Release Report — v0.1.0

**Date:** 2026-10-14  
**Target Architecture:** `amd64` (x86_64)  
**Release Version:** `v0.1.0`  
**Build ID:** `20261014-1409-5cadbfc`  

---

## 1. URLs & References

- **GitHub Repository URL:** https://github.com/10974-Spec/alien-linux-os
- **GitHub Release URL:** https://github.com/10974-Spec/alien-linux-os/releases/tag/v0.1.0
- **Git Commit (HEAD):** `e1a7a29` (verified matching remote `origin/main`)

---

## 2. ISO Specifications & Checksums

- **Target ISO:** `alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso`
- **Total Uncompressed Size:** 2,593,005,568 bytes (~2.41 GiB)
- **Official SHA-256 Checksum:** `f0d51e03ebcaa7dc264dc68913f51a3f7e40351dbe99d00e42d8c3374b1fda47`

### Multi-Part Release Assets (GitHub 2 GiB Limit Compliance)
Because GitHub Release assets are capped at 2 GiB per file, the ISO is distributed in two parts:
1. `alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.00.part` (1,992,294,400 bytes, ~1.9 GB)  
   SHA-256: `6d6e5849149e76afb2cec87cf447317c90e5200729317b4d2382bf284c7bdca6`
2. `alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.01.part` (600,711,168 bytes, ~573 MB)  
   SHA-256: `6ac565913e8efc735cc08e48806f653dc5bdaebee3396f65cf73400c70310022`
3. `SHA256SUMS`

**Verification & Reassembly Command:**
```bash
cat alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso.*.part > alien-lite-v0.1.0-20261014-1409-5cadbfc-amd64.iso
sha256sum -c SHA256SUMS
```

---

## 3. Repository Size & History Hygiene

- **Working tree large files (`out/`):** Strictly excluded via `.gitignore` (`out/*.iso`, `*.qcow2`, `*.deb`, etc.).
- **Blobs in git history > 50 MB:** **0** (verified with `git rev-list --objects --all`).
- **Largest blob in history:** `packages/alien-store/usr/bin/cosmic-store` (46.7 MB), well within GitHub's 100 MB rejection limit.
- **Total repository pack pushed:** ~178 MB (includes all system source, tools, UI artwork, and documentation).
- **Secrets check:** 100% clean. Zero private keys, tokens, or credentials committed.

---

## 4. Key Deliverables & Changes

- `README.md`: Comprehensive guide with visual showcases, ISO verification, QEMU/VirtualBox instructions, USB creation, building from source, known issues, and third-party credits.
- `LICENSE`: GNU General Public License v3.0 for Alien OS tooling and scripts.
- `THIRD-PARTY.md`: Complete attribution for VLC, LXQt, Brave, Ghostwriter, FeatherPad, Papirus, and Icons8.
- `.gitignore`: Extended to block all ISOs, virtual disks, deb packages, build caches, and test artifacts.
- `docs/ship-proof/wallpapers/`: Screenshots from booted live session showing default wallpaper (`panel_3_1`), wallpaper preferences chooser, and live resolution tests.

---

## 5. Security & Maintenance Actions for You

> [!IMPORTANT]
> **Token Rotation Recommended**:
> The GitHub Personal Access Token used to authenticate the GitHub CLI session was provided directly in the chat session. Although it was never written to any file in the repository or committed to git, as a security best practice, please visit **GitHub Settings → Developer Settings → Personal Access Tokens** and rotate or revoke the token now that the release has been shipped.
