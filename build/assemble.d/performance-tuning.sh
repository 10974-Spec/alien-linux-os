#!/usr/bin/env bash
# Alien OS — Memory, ZRAM, cgroup Slices & Hardware Tuning Assemble Script (Phases 6 & 7)
set -euo pipefail

# 1. ZRAM Generator configuration
DEST_ZRAM="$WORK/config/includes.chroot/etc/systemd"
mkdir -p "$DEST_ZRAM"
cat > "$DEST_ZRAM/zram-generator.conf" <<'EOF'
# Alien OS ZRAM Configuration (ZSTD compression, dynamic memory sizing)
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# 2. User Slices for Desktop Protection (cgroup v2)
DEST_USER_SLICES="$WORK/config/includes.chroot/etc/systemd/user"
mkdir -p "$DEST_USER_SLICES"

cat > "$DEST_USER_SLICES/dev.slice" <<'EOF'
# Protected slice for background developer workloads and compilations
[Slice]
Description=Developer Workloads Slice
CPUWeight=50
IOWeight=50
MemoryHigh=80%
EOF

cat > "$DEST_USER_SLICES/app.slice" <<'EOF'
# High priority slice for interactive desktop sessions
[Slice]
Description=Interactive Desktop Applications Slice
CPUWeight=100
IOWeight=100
EOF

# 3. Systemd-OOMD Policy
cat > "$DEST_ZRAM/oomd.conf" <<'EOF'
[OOM]
SwapUsedLimit=90%
DefaultMemoryPressureLimit=60%
DefaultMemoryPressureDurationSec=30
EOF

# 4. Dev Terminal Desktop Entry (opens terminal inside dev.slice)
DEST_APPS="$WORK/config/includes.chroot/usr/share/applications"
mkdir -p "$DEST_APPS"
cat > "$DEST_APPS/alien-terminal-dev.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Dev Terminal (Protected dev.slice)
GenericName=Developer Terminal
Comment=Terminal session isolated in dev.slice to prevent desktop lockups
Exec=alien-dev-run qterminal
Icon=utilities-terminal
Terminal=false
Categories=Development;System;TerminalEmulator;
EOF

# 5. Alien Recover Desktop Entry
cat > "$DEST_APPS/alien-recover.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Alien System Recovery
GenericName=System Snapshot Recovery
Comment=Restore system from a previous snapshot
Exec=alien-recover
Icon=system-reboot
Terminal=false
Categories=System;Settings;
EOF

echo "  - Configured ZRAM generator, dev.slice, oomd policy, and desktop launchers"
