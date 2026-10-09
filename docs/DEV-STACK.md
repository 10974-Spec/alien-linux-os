# Alien OS Developer Stack

Alien OS Lite comes preinstalled with a complete, modern development stack: **PostgreSQL**, **MongoDB**, and **Visual Studio Code**.

---

## 1. Stack Components & Verification

### PostgreSQL (Version 17)
- **Source:** Debian 13 "Trixie" Official Repositories (`main`).
- **Packages Installed:** `postgresql`, `postgresql-client`, `pgcli`.
- **Boot State:** Disabled by default (`systemctl disable postgresql`).
- **Network Binding:** Bound to `localhost` (`127.0.0.1`) only.
- **Authentication:** Local peer authentication (`peer` method in `pg_hba.conf`).
  - No default passwords.
  - An initial role named after the login user (`alien`) is created with `CREATEDB` permissions, along with a default database named `alien`.
  - Connect directly with `psql` or `pgcli` without password prompts.
- **Connection URI:** `postgresql://alien@localhost:5432/alien`

### MongoDB Community Server (Version 8.0)
- **Source:** MongoDB Official APT Repository (`repo.mongodb.org`).
- **Repository URI:** `http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main`
- **Signing Key URL:** `https://www.mongodb.org/static/pgp/server-8.0.asc`
- **Signing Key Fingerprint:**
  ```text
  pub   rsa4096 2024-01-11 [SC]
        4B07 52C1 BCA2 38C0 B4EE 14DC 41DE 058A 4E7D CA05
  uid   MongoDB 8.0 Release Signing Key <packaging@mongodb.com>
  ```
- **Debian 13 Compatibility Note:** MongoDB publishes tools for trixie, while full server packages (`mongodb-org-server`) are published in the `bookworm` suite. The bookworm 8.0 build was thoroughly tested in the Debian 13 (Trixie) container environment: it installs with zero dependency conflicts and runs natively with `OpenSSL 3.x`.
- **Packages Installed:** `mongodb-org-server`, `mongodb-mongosh`, `mongodb-database-tools`.
- **Boot State:** Disabled by default (`systemctl disable mongod`).
- **Network Binding:** Bound strictly to `127.0.0.1` on port `27017` in `/etc/mongod.conf`.
- **Data Directory:** `/var/lib/mongodb` (owned by `mongodb:mongodb`).
- **Connection URI:** `mongodb://127.0.0.1:27017/`

### Visual Studio Code
- **Source:** Microsoft Official APT Repository (`packages.microsoft.com`).
- **Repository URI:** `https://packages.microsoft.com/repos/code stable main`
- **Signing Key URL:** `https://packages.microsoft.com/keys/microsoft.asc`
- **Signing Key Fingerprint:**
  ```text
  pub   rsa2048 2015-10-28 [SC]
        BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF
  uid   Microsoft (Release signing) <gpgsecurity@microsoft.com>
  ```
- **Packages Installed:** `code`.
- **Virtual Machine / Software Rendering Support:**
  A smart launcher is installed at `/usr/local/bin/code`. It detects virtualized or software-rasterized environments (QEMU, llvmpipe, swrast) and automatically appends `--disable-gpu` to ensure crash-free execution.
- **Recommended Extensions:** Preseeded in `/etc/skel/.vscode/extensions.json` (Python, ESLint, Prettier, MongoDB, PostgreSQL).
- **Open Source Alternative:** Users wishing to avoid Microsoft proprietary telemetry/licensing may switch to **VSCodium** (`vscodium`) as a drop-in binary replacement.

---

## 2. Dev Services Manager (`alien-dev-services`)

Alien OS includes the `alien-dev-services` utility for managing database services:
- **Graphical Mode:** Launch "Dev Services" from the Application Menu or run `alien-dev-services` in a terminal.
- **Command Line Mode:**
  ```bash
  alien-dev-services status               # Show service states and connection strings
  alien-dev-services start postgresql     # Start PostgreSQL
  alien-dev-services stop postgresql      # Stop PostgreSQL
  alien-dev-services start mongodb        # Start MongoDB
  alien-dev-services stop mongodb         # Stop MongoDB
  alien-dev-services enable postgresql    # Enable PostgreSQL at boot
  alien-dev-services disable postgresql   # Disable PostgreSQL at boot
  ```
- **Live Persistence Warning:** When running on a live USB session without persistence, `alien-dev-services` displays a clear visual warning alerting the developer that databases stored in RAM will not survive a reboot.

---

## 3. Size and Resource Footprint

- **Idle RAM:** Because PostgreSQL and MongoDB services are **disabled at boot**, idle RAM usage upon login is unaffected (~320–380 MB).
- **ISO Size Impact:** The developer stack adds approximately 180–220 MB of compressed squashfs data to the ISO image.
- **Trimming Options (if smaller ISO is desired):**
  1. Remove `mongodb-database-tools` (~65 MB uncompressed).
  2. Substitute VS Code with a light editor or provide a one-click install script.
  3. Strip debug symbols and documentation manpages from postgres packages.
