#!/usr/bin/env bash
# Alien — apply security baseline sysctl parameters
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

DEST="$WORK/config/includes.chroot/etc/sysctl.d"
mkdir -p "$DEST"

cat > "$DEST/99-alien-security.conf" <<'EOF'
# Alien OS Hardened Sysctl Parameters
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
kernel.yama.ptrace_scope = 1
fs.protected_fifos = 2
fs.protected_regular = 2
vm.mmap_min_addr = 65536
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
kernel.unprivileged_userns_clone = 1
EOF

echo "  - Installed /etc/sysctl.d/99-alien-security.conf"
