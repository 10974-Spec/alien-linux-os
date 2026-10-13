#!/usr/bin/env bash
# Alien OS — Media Stack & Hardware Video Decode Configuration (Phase 8)
set -euo pipefail

# 1. VLC media player configuration (hardware acceleration & sensible defaults)
DEST_VLC="$WORK/config/includes.chroot/etc/skel/.config/vlc"
mkdir -p "$DEST_VLC"
cat > "$DEST_VLC/vlcrc" <<'EOF'
[main]
one-instance=1
playlist-enqueue=1
metadata-network-access=0
album-art=0

[qt]
qt-privacy-ask=0
qt-updates-notif=0
qt-notification=0

[avcodec]
avcodec-hw=any
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
  "DefaultBrowserSettingEnabled": true,
  "PromotionsEnabled": false,
  "BraveRewardsDisabled": true,
  "BraveWalletDisabled": true,
  "BraveVPNDisabled": true,
  "BraveAIChatEnabled": false,
  "MetricsReportingEnabled": false,
  "HardwareAccelerationModeEnabled": true,
  "HideWebStorePromo": true,
  "SpellcheckEnabled": true
}
EOF

echo "  - Configured MPV and Brave hardware acceleration settings"
