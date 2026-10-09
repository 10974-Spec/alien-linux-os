#!/usr/bin/env bash
# Alien OS — Enable Flathub remote repository
set -euo pipefail

echo ">>> Enabling Flathub for Alien OS..."

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Installing Flatpak subsystem..."
    apt-get update -y
    apt-get install -y flatpak
fi

echo "Adding Flathub remote..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Flathub successfully enabled! Flatpak packages can now be searched and installed."
