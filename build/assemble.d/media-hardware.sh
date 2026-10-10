#!/usr/bin/env bash
# Alien OS — Media Stack & Hardware Video Decode Configuration (Phase 8)
set -euo pipefail

# 1. MPV safe hardware decoding defaults
DEST_MPV="$WORK/config/includes.chroot/etc/mpv"
mkdir -p "$DEST_MPV"
cat > "$DEST_MPV/mpv.conf" <<'EOF'
# Alien OS Default MPV Configuration
hwdec=auto-safe
vo=gpu
profile=fast
EOF

# 2. Brave VA-API Hardware Decode Flags
DEST_SKEL="$WORK/config/includes.chroot/etc/skel/.config"
DEST_ETC_BRAVE="$WORK/config/includes.chroot/etc/brave"
mkdir -p "$DEST_SKEL" "$DEST_ETC_BRAVE"

cat > "$DEST_SKEL/brave-flags.conf" <<'EOF'
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-zero-copy
EOF

# Also preseed for policies if managed
mkdir -p "$DEST_ETC_BRAVE/policies/managed"
cat > "$DEST_ETC_BRAVE/policies/managed/alien-policy.json" <<'EOF'
{
  "HardwareAccelerationModeEnabled": true
}
EOF

echo "  - Configured MPV and Brave hardware acceleration settings"
