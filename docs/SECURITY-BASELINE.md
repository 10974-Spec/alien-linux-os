# Alien OS Security Baseline & Hardening Audit

**Document:** `docs/SECURITY-BASELINE.md`  
**Target:** Alien OS 0.1+ (Lite and Full editions)  
**Date:** 2026-10-11  

> [!IMPORTANT]
> The configurations described in this document constitute progressive system hardening to reduce attack surface and prevent common privilege escalations. They represent defensive depth, not an absolute guarantee against compromise.

---

## 1. Network & Firewall

- **Default Inbound Policy:** Deny all incoming connections (`ufw default deny incoming`).
- **Default Outbound Policy:** Allow outgoing connections (`ufw default allow outgoing`).
- **Listening Ports (`ss -tulpn`):**
  - No OpenSSH server running or listening by default on live or installed systems.
  - No telnet, rpcbind, NFS, or Samba services installed in the Lite edition.
  - `cups-browsed` is disabled by default to eliminate remote vulnerability exposure (CVE-2024-47176 family).

---

## 2. Kernel & Sysctl Parameters

Hardened sysctl configuration is enforced at `/etc/sysctl.d/99-alien-security.conf`:

```ini
# Kernel pointer and log restriction
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1

# BPF Hardening
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# Process tracing protection
kernel.yama.ptrace_scope = 1

# Filesystem link & FIFO protections
fs.protected_fifos = 2
fs.protected_regular = 2
vm.mmap_min_addr = 65536

# Network stack hardening
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1

# CRITICAL COMPATIBILITY: Unprivileged user namespaces REMAIN ENABLED
# Required for Chromium/Brave sandbox isolation and rootless Podman containers
kernel.unprivileged_userns_clone = 1
```

---

## 3. AppArmor Sandboxing Profiles

AppArmor profiles for the new application suite are located in `/etc/apparmor.d/`:

| Application | Network Access Allowed | Filesystem Scope | Profile Status |
|---|---|---|---|
| `alien-player` | Yes (HTTP/HLS streaming only) | Read media (`~/Videos`, `~/Music`); write config | Enforce |
| `alien-viewer` | **No** (Denied) | Read images (`~/Pictures`); write temp/cache | Enforce |
| `alien-notes` | **No** (Denied) | Read/write `~/Notes/` and local config only | Enforce |
| `alien-webapp` | Yes (via Brave sandbox) | `~/.local/share/alien/webapps/<id>/` | Enforce (Brave domain) |

---

## 4. Repository & APT Supply Chain Security

All external third-party repositories are pinned and strictly isolated:
- **Brave Browser:**
  - Keyring: `/usr/share/keyrings/brave-browser-archive-keyring.gpg`
  - Fingerprint: `DBF1 A116 C220 B8C7 164F 9823 0686 B784 2003 8257`
  - Signed-by pinned: `[signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg]`
  - APT Pinning: Priority 500, restricted to `brave-browser*`
- **VS Code:**
  - Keyring: `/usr/share/keyrings/microsoft-vscode.gpg`
  - Pinned specifically to `code` packages only.
- **Strict Prohibition:** No `[trusted=yes]` entries exist anywhere in the repository or live-build configurations.

---

## 5. Account and Privilege Separation

- **Live Session:** Passwordless `sudo` is enabled strictly for the live user (`alien`) to support live installation and diagnosis.
- **Installed Systems:** Calamares locks root and configures a non-default user account with standard password-protected `sudo`.
