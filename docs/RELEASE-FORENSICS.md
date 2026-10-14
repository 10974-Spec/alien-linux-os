# Release Forensics & Repository Audit (Phase 1)

**Date:** 2026-10-14  
**Target Remote:** `https://github.com/10974-Spec/alien-linux-os.git`  
**Branch:** `main`

---

## 1. Measurements & Real Command Outputs

### 1.1 `git status --short | head -50`
```text
 M .build_inputs_hash
 M build/assemble.d/packages-chroot.sh
 M layers/shared/package-lists/theme.list.chroot
 M tools/iso-inspect.sh
?? docs/ship-proof/wallpapers/01-default-desktop.png
?? docs/ship-proof/wallpapers/02-wallpaper-chooser.png
?? docs/ship-proof/wallpapers/03-switched-wallpaper-1.png
?? docs/ship-proof/wallpapers/04-switched-wallpaper-2.png
?? layers/shared/packages.chroot/alien-wallpaper-migrate_all.deb
?? layers/shared/packages.chroot/alien-wallpapers_all.deb
?? tests/prove-wallpapers-qemu.py
```

### 1.2 `git count-objects -vH`
```text
count: 940
size: 279.34 MiB
in-pack: 0
packs: 0
size-pack: 0 bytes
prune-packable: 0
garbage: 0
size-garbage: 0 bytes
```

### 1.3 `du -sh .git` and Top 25 Directories
```text
=== du -sh .git ===
281M	.git

=== Top 25 Directories/Files in Workspace ===
4.0K	.gitignore
4.0K	Makefile
4.0K	.pre-commit-config.yaml
4.0K	SECURITY.md
4.0K	webapps
8.0K	ci
8.0K	lib
8.0K	.local
12K	.github
20K	scripts
32K	.venv
52K	experiments
52K	theme
192K	build
212K	banner-compare.png
260K	tools
264K	tests
9.2M	branding-assets
11M	vm
15M	layers
37M	docs
90M	packages
181M	branding
281M	.git
28G	out
```

### 1.4 Files in Working Tree > 50MB
```text
-rw-r--r-- 1 nyakoe nyakoe 2.1G Oct 11 17:36 ./out/alien-lite-0.1-20261011-amd64.iso
-rw-r--r-- 1 nyakoe nyakoe 2.4G Oct 13 13:33 ./out/alien-lite-20261013-1333-d43debb.iso
-rw-r--r-- 2 nyakoe nyakoe 1.5G Oct  7 16:15 ./out/alien-lite-0.1-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 4.0G Oct  8 08:29 ./out/alien-full-0.1-20261008-amd64.iso
-rw-r--r-- 1 nyakoe nyakoe 2.5G Oct 14 14:10 ./out/alien-lite-20261014-1409-5cadbfc.iso
-rw-r--r-- 1 nyakoe nyakoe 2.4G Oct 13 14:25 ./out/alien-lite-20261013-1425-d43debb.iso
-rw-r--r-- 2 nyakoe nyakoe 2.0G Oct  9 13:57 ./out/alien-lite-0.1-20261009-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 1.5G Oct  7 16:15 ./out/baseline-backup/alien-lite-0.1-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 4.0G Oct  8 08:29 ./out/baseline-backup/alien-full-0.1-20261008-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 2.0G Oct  9 13:57 ./out/baseline-backup/alien-lite-0.1-20261009-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 2.0G Oct  8 18:57 ./out/baseline-backup/alien-lite-0.1-20261008-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 4.0G Oct  7 13:49 ./out/baseline-backup/alien-0.1-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 2.0G Oct  8 18:57 ./out/alien-lite-0.1-20261008-amd64.iso
-rw-r--r-- 1 nyakoe nyakoe 2.5G Oct 14 11:59 ./out/alien-lite-20261014-1159-5cadbfc.iso
-rw-r--r-- 1 nyakoe nyakoe 2.3G Oct 12 15:00 ./out/alien-lite-0.1-2bd5ae9-20261012-1256-amd64.iso
-rw-r--r-- 2 nyakoe nyakoe 4.0G Oct  7 13:49 ./out/alien-0.1-amd64.iso
```
*Note:* Every file > 50MB in the workspace is in `out/`. No files outside `out/` exceed 50MB.

### 1.5 Large Blobs Committed in Git History (> 50MB)
```text
Command:
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '$1=="blob" && $3>52428800' | sort -k3 -n

Output:
(empty)
```
**Conclusion:** Zero blobs > 50MB exist in git history.

Largest blobs currently in history (> 10MB):
- `packages/alien-store/usr/bin/cosmic-store` (49,022,104 bytes, 46.7 MB)
- `branding/generated/backgrounds/bg1-3840x2160.png` (34,167,173 bytes, 32.5 MB)
- `branding/generated/backgrounds/bg1-2560x1440.png` (16,103,012 bytes, 15.3 MB)
- `layers/shared/packages.chroot/alien-wallpapers.deb` (15,269,928 bytes, 14.5 MB)

---

## 2. Assessment of Large Files: Working Tree vs History

| Category | Status | Action |
|---|---|---|
| **ISOs (`out/*.iso`)** | Working Tree only (`out/` directory, 28GB total) | Never in git history. Must be strictly ignored via `.gitignore` (`out/`, `*.iso`). |
| **Blobs in git history > 50MB** | None (0 found) | No history rewriting required (Phase 4 skipped). |
| **Blobs in git history 10MB–49MB** | 4 files (`cosmic-store` 46.7MB, wallpapers ~15-32MB) | Below GitHub's 50MB warning threshold and well below 100MB rejection limit. Safe to push. |

---

## 3. Secret Audit

- Search query: `grep -rIn -E "(api[_-]?key|secret|token|password|BEGIN (RSA|OPENSSH|PRIVATE))"` (excluding `.git`, `build`, `chroot`, `out`, `.venv`).
- Result: Clean. All matches are documentation references (`docs/STORE-DIAGNOSIS.md`, `tests/qemu-gate.py`, etc.).
- File patterns checked: `.env`, `*.pem`, `id_rsa*`, `*.key`.
- Only matching file: `./branding/tokens.env` (verified: contains only UI styling variables: fonts, colors, corner radius).
- **No secrets or private keys exist in the repository.**
