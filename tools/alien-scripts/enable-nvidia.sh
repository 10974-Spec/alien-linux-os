#!/usr/bin/env bash
# Alien — install NVIDIA proprietary drivers
set -euo pipefail

echo "Alien: Enabling NVIDIA drivers..."
sudo apt-get update
sudo apt-get install -y nvidia-driver firmware-misc-nonfree

echo "Done. Please reboot your computer to use the NVIDIA drivers."
