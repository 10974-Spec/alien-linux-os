#!/usr/bin/env bash
# Alien — install Waydroid (Android apps on Linux)
set -euo pipefail

echo "Alien: Enabling Waydroid..."
sudo apt-get update
sudo apt-get install -y curl ca-certificates
curl -s https://repo.waydro.id | sudo bash
sudo apt-get install -y waydroid

echo "Initializing Waydroid..."
sudo waydroid init

echo "Done. You can now launch Waydroid from the app menu."
echo "Note: Waydroid only works on a Wayland session."
