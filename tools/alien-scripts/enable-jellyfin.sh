#!/usr/bin/env bash
# Alien — install Jellyfin media server
set -euo pipefail

echo "Alien: Enabling Jellyfin..."
curl -s https://repo.jellyfin.org/install-debuntu.sh | sudo bash

echo "Done. Jellyfin is running. Open http://localhost:8096 to configure it."
