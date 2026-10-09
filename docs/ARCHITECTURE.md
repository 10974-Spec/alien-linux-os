# Architecture

Alien OS is a Debian-based custom distribution built using `live-build`.

## Components
1. **Build System**: Uses a Debian container (`alien-builder:trixie`) via Podman/Docker to securely build ISO images without altering the host system.
2. **Editions**:
   - **Lite**: Openbox + LXQt panel. Aimed at older hardware and low resources.
   - **Full**: KDE Plasma. Aimed at modern hardware.
3. **Layers**: Configuration and package lists are split into `shared/`, `lite/`, and `full/` inside `layers/`.
4. **Custom Tools**: Found in `tools/` and `packages/` (packaged as deb).
