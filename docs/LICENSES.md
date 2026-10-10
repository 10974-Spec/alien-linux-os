# Alien OS Third-Party Licenses and Credits

This document details the software components, third-party libraries, and assets integrated into Alien OS.

---

## 1. Developer Stack

### PostgreSQL
- **Component:** PostgreSQL Server & Client (`postgresql`, `postgresql-client`, `pgcli`)
- **License:** PostgreSQL License (liberal open source license similar to BSD or MIT)
- **Copyright:** (C) 1996-2024 The PostgreSQL Global Development Group
- **Website:** https://www.postgresql.org/

### MongoDB Community Server
- **Component:** MongoDB Server, MongoSH Shell, Database Tools (`mongodb-org-server`, `mongodb-mongosh`, `mongodb-database-tools`)
- **License:** Server Side Public License (SSPL) Version 1 / Apache-2.0 (mongosh and tools)
- **Copyright:** (C) 2007-present MongoDB, Inc.
- **Website:** https://www.mongodb.com/
- **Distribution Notice:** MongoDB Community Server is licensed under the SSPL. If distributing Alien OS commercially or offering MongoDB as a managed service, review the SSPL requirements.

### Visual Studio Code
- **Component:** Visual Studio Code (`code`)
- **License:** Microsoft Software License Terms (Proprietary binaries built from the open-source vscode repository)
- **Copyright:** (C) Microsoft Corporation
- **Website:** https://code.visualstudio.com/
- **Distribution Notice & Alternative:** The official VS Code binaries include Microsoft branding and telemetry components under the Microsoft Software License. For public distributions requiring 100% FLOSS licensing, **VSCodium** (licensed under the MIT License) serves as a direct drop-in replacement.

---

## 2. Desktop Environment & Core Utilities

### LXQt Desktop
- **Component:** LXQt Desktop (`lxqt-core`, `lxqt-panel`, `lxqt-session`, `lxqt-runner`, `pcmanfm-qt`)
- **License:** GNU LGPL v2.1+ / GNU GPL v2+
- **Copyright:** The LXQt Project Developers
- **Website:** https://lxqt-project.org/

### Window Manager & Compositor
- **Component:** Openbox (`openbox`), Picom Compositor (`picom`)
- **License:** GNU GPL v2 / MIT
- **Copyright:** Dana Jansens, Mikael Magnusson, Derek Foreman, Yuxuan Shui, et al.

### Dialog Utility
- **Component:** Zenity (`zenity`)
- **License:** GNU Lesser General Public License version 2.1 (LGPLv2.1)
- **Copyright:** Copyright (C) 2002 Sun Microsystems, Inc.

### Icon and Cursor Themes
- **Component:** Papirus Icon Theme (`papirus-icon-theme`)
- **License:** GNU GPL v3
- **Copyright:** Papirus Development Team
- **Component:** Bibata Cursor Theme (`bibata-cursor-theme`)
- **License:** GNU GPL v3
- **Copyright:** Kauntal Majumder (AbdulKaiz)

---

## 3. Application Store & Frameworks

### PyQt6 & Qt6
- **Component:** PyQt6 (`python3-pyqt6`, `python3-pyqt6.qtsvg`)
- **License:** GNU General Public License v3 (GPLv3)
- **Copyright:** (C) Riverbank Computing Limited

### AppStream & PackageKit
- **Component:** AppStream (`appstream`), PackageKit (`packagekit`)
- **License:** GNU LGPL v2.1+ / GNU GPL v2+
- **Copyright:** Matthias Klumpp, Richard Hughes, et al.

---

## 4. Alien OS Custom Assets & Themes
- **Logos & UI Artwork:** Alien Project (Original Artwork)
- **Alien LXQt Theme & Custom Wallpapers:** Alien Project
- **Alien App Center & Alien Dev Services:** Alien Project
- **License:** MIT License

---

## 5. Architecture Tools & System Utilities

### Alien Architecture Tool Suite
- **Components:** `alien-banner`, `alien-snapshot`, `alien-recover`, `alien-protect`, `alien-tune`, `alien-dev-run`, `alien-sandbox`, `alien-audio-profile`, `alien-gpu-check`, `alien-guard`, `alien-doctor`, `alien-pkg`
- **License:** MIT License
- **Copyright:** (C) Alien OS Project

### Upstream Storage & Power Utilities
- **Snapper:** GNU General Public License v2 (GPL-2.0) — SUSE LLC / openSUSE Project
- **Btrfs-progs:** GNU General Public License v2 (GPL-2.0) — Chris Mason, David Sterba, et al.
- **TLP:** GNU General Public License v2+ (GPL-2.0+) — Thomas Koch (LinRunner)
- **systemd-zram-generator:** MIT License — Zbigniew Jędrzejewski-Szmek, et al.
- **PipeWire:** MIT License — Wim Taymans, Red Hat, Inc.

