# Alien App Center

**Alien App Center** is a curated, lightweight graphical application store designed for **Alien OS Lite**. It provides a clean, Pop!_OS "Pop Shop" inspired interface with zero unnecessary background daemons.

---

## 1. Architectural Choice & Framework Comparison

> **Implementation:** Built Alien App Center as a lightweight Python PyQt6 application with PackageKit/polkit and AppStream metadata.

### Evaluation of Ready-Made Alternatives:
Before building the custom App Center, we evaluated **KDE Discover** and **GNOME Software**:

| Metric | GNOME Software (`gnome-software`) | KDE Discover (`plasma-discover`) | **Alien App Center** |
| :--- | :--- | :--- | :--- |
| **GUI Framework** | GTK 4 / Adwaita | Qt 6 / Kirigami / KDE Frameworks | **Qt 6 (PyQt6)** (Native to LXQt) |
| **Installed Size** | ~165 MB + GNOME dependencies | ~185 MB + KDE Frameworks | **~18 MB** (Shares LXQt Qt6 libs) |
| **Idle RAM Footprint** | ~75–120 MB (Background daemon) | ~80–110 MB (KDE worker services) | **0 MB** (No persistent background daemon) |
| **Desktop Aesthetics** | Disjointed GNOME CSD styling | Mixed KDE/Breeze widgets | **Native Alien OS Fusion & Dark Theme** |
| **Bundles & Web Apps** | Requires custom plugins | Not supported natively | **Built-in Add-Ons & Web App engine** |

**Conclusion:** A dedicated PyQt6 application matching LXQt 2.1 design tokens is dramatically lighter, boots faster, and provides superior integration without bloating the Lite edition.

---

## 2. Store Features

- **Sidebar Navigation:** Home, Categories, Installed, Updates, Bundles, Settings.
- **Header Search Bar:** Live searching across curated picks, AppStream catalog (`appstreamcli`), and APT package repository (`apt-cache`).
- **Hero / Featured Section:** Hand-picked recommendations displayed in large visual cards.
- **Curated Categories:**
  1. **Developer:** Visual Studio Code, PostgreSQL, MongoDB, Git, Python 3, Node.js, Podman. (Preinstalled tools are marked as *Installed* with a direct shortcut to *Dev Services*).
  2. **Social:** Telegram Desktop, WhatsApp Web, Discord, Instagram, TikTok.
  3. **Music:** Spotify Web, Audacious, VLC, Navidrome.
  4. **Movies and Manga:** VLC, MPV Player, Foliate, Jellyfin.
  5. **Chess:** Lichess, Chess.com, PyChess, GNU Chess.
  6. **Office:** LibreOffice Suite, FeatherPad.
  7. **Graphics:** GIMP, Inkscape, Krita.
  8. **Utilities:** QTerminal, PCManFM-Qt, Ark Archiver, Htop.
  9. **System:** LXQt Configuration Center, Dev Services Manager, Calamares.
- **Add-On Bundles:** Direct GUI execution of server suites (Jellyfin Media Server, Navidrome Music Server, Waydroid, Web App Creator).
- **Offline Tolerance:** Auto-detects network disconnection and displays an informational banner without freezing; installed applications and cached lists remain accessible.
- **Safe Privilege Escalation:** Utilizes `pkexec` over polkit so that the App Center UI never runs as root.

---

## 3. How to Add New Apps, Categories, and Picks

All curated catalog metadata is defined in `/usr/lib/alien-app-center/alien-picks.yaml` (source: `app-center/alien-picks.yaml`).

### Adding an App to an Existing Category:
Add an entry under the corresponding category's `apps:` list:
```yaml
- id: "audacity"
  package: "audacity"
  name: "Audacity"
  summary: "Multi-track audio editor and recorder"
  description: "Audacity is an easy-to-use, multi-track audio editor and recorder for Windows, macOS, GNU/Linux and other operating systems."
  icon: "audacity"
  version: "3.6"
  size: "28 MB"
  installed_size: "85 MB"
  source: "Debian Trixie"
  exec: "audacity"
```

### Adding a New Category:
Add an entry under `categories:`:
```yaml
- id: "science"
  name: "Science & Education"
  icon: "applications-science"
  summary: "Astronomy, mathematics, and educational software"
  apps:
    - id: "stellarium"
      package: "stellarium"
      name: "Stellarium"
      summary: "Planetarium software showing realistic 3D skies"
      icon: "stellarium"
      exec: "stellarium"
```

### Featuring an App on the Home Screen:
Set `featured: true` on any app definition to promote it to the Home hero banner.

---

## 4. Flathub & Flatpak Integration

Flathub is disabled by default to keep the ISO footprint small and clean.
- Users can enable Flathub from **Settings -> Enable Flathub**.
- Alternatively, via CLI:
  ```bash
  pkexec /usr/lib/alien-app-center/enable-flathub.sh
  ```
