#!/usr/bin/env bash
# Alien — install Navidrome music server
set -euo pipefail

echo "Alien: Enabling Navidrome..."
# Navidrome doesn't have a simple apt repo, so we'll install it manually
# This is a basic setup script.
cd /tmp
wget https://github.com/navidrome/navidrome/releases/latest/download/navidrome_linux_amd64.tar.gz
tar -xvzf navidrome_linux_amd64.tar.gz

sudo mkdir -p /opt/navidrome /var/lib/navidrome
sudo cp navidrome /opt/navidrome/
sudo chown -R $USER:$USER /opt/navidrome /var/lib/navidrome

cat <<EOF | sudo tee /etc/systemd/system/navidrome.service
[Unit]
Description=Navidrome Music Server and Streamer compatible with Subsonic/Airsonic
After=network.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/opt/navidrome/navidrome --dataFolder /var/lib/navidrome --config /opt/navidrome/navidrome.toml
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now navidrome.service

echo "Done. Navidrome is running. Open http://localhost:4533 to configure it."
