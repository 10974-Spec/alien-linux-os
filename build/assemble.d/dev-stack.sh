#!/usr/bin/env bash
# Alien — Developer Stack Preseed (PostgreSQL, MongoDB, VS Code, Dev Services)
set -euo pipefail

DEST_KEYRINGS="$WORK/config/includes.chroot/etc/apt/keyrings"
DEST_SOURCES="$WORK/config/includes.chroot/etc/apt/sources.list.d"
DEST_BIN="$WORK/config/includes.chroot/usr/bin"
DEST_LOCAL_BIN="$WORK/config/includes.chroot/usr/local/bin"
DEST_APPS="$WORK/config/includes.chroot/usr/share/applications"
DEST_SKEL_VSCODE="$WORK/config/includes.chroot/etc/skel/.vscode"
DEST_HOOKS="$WORK/config/hooks/normal"

mkdir -p "$DEST_KEYRINGS" "$DEST_SOURCES" "$DEST_BIN" "$DEST_LOCAL_BIN" "$DEST_APPS" "$DEST_SKEL_VSCODE" "$DEST_HOOKS"

# 1. Install APT Repositories & Keyrings for MongoDB and VS Code
if [ -f "$SRC/layers/shared/keyrings/mongodb-server-8.0.gpg" ]; then
    cp "$SRC/layers/shared/keyrings/mongodb-server-8.0.gpg" "$DEST_KEYRINGS/mongodb-server-8.0.gpg"
    mkdir -p "$WORK/config/includes.chroot/usr/share/keyrings"
    cp "$SRC/layers/shared/keyrings/mongodb-server-8.0.gpg" "$WORK/config/includes.chroot/usr/share/keyrings/mongodb-server-8.0.gpg"
fi

if [ -f "$SRC/layers/shared/keyrings/packages.microsoft.gpg" ]; then
    cp "$SRC/layers/shared/keyrings/packages.microsoft.gpg" "$DEST_KEYRINGS/packages.microsoft.gpg"
    mkdir -p "$WORK/config/includes.chroot/usr/share/keyrings"
    cp "$SRC/layers/shared/keyrings/packages.microsoft.gpg" "$WORK/config/includes.chroot/usr/share/keyrings/packages.microsoft.gpg"
fi

cat > "$DEST_SOURCES/mongodb-org-8.0.list" <<'EOF'
deb [arch=amd64 signed-by=/etc/apt/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main
EOF

cat > "$DEST_SOURCES/vscode.list" <<'EOF'
deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main
EOF

# 2. VS Code default extension recommendations
cat > "$DEST_SKEL_VSCODE/extensions.json" <<'EOF'
{
  "recommendations": [
    "ms-python.python",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "mongodb.mongodb-vscode",
    "ckolkman.vscode-postgres"
  ]
}
EOF

# 3. VS Code Smart GPU / Software-rendering Wrapper (/usr/local/bin/code)
cat > "$DEST_LOCAL_BIN/code" <<'EOF'
#!/usr/bin/env bash
# Alien OS — VS Code smart launcher (detects software rendering / QEMU and passes --disable-gpu)
EXTRA_FLAGS=()

# Check for lack of hardware acceleration or llvmpipe / swrast
if [ ! -e /dev/dri/renderD128 ] && [ ! -e /dev/dri/card0 ]; then
    EXTRA_FLAGS+=(--disable-gpu)
elif command -v glxinfo >/dev/null 2>&1; then
    RENDERER=$(glxinfo 2>/dev/null | grep -i "OpenGL renderer string" || true)
    if echo "$RENDERER" | grep -iq "llvmpipe\|software\|virgl\|swrast"; then
        EXTRA_FLAGS+=(--disable-gpu)
    fi
fi

exec /usr/bin/code "${EXTRA_FLAGS[@]}" "$@"
EOF
chmod +x "$DEST_LOCAL_BIN/code"

# 4. PostgreSQL User/Role Initializer (/usr/bin/alien-pg-init)
cat > "$DEST_BIN/alien-pg-init" <<'EOF'
#!/usr/bin/env bash
# Alien OS — Initialize PostgreSQL peer role & database for login user
set -euo pipefail

TARGET_USER="${1:-${USER:-alien}}"

# If run under sudo, default to SUDO_USER
if [ -n "${SUDO_USER:-}" ] && [ "$TARGET_USER" = "root" ]; then
    TARGET_USER="$SUDO_USER"
fi

# Ensure PostgreSQL service is active
if ! systemctl is-active --quiet postgresql; then
    echo "PostgreSQL is not running. Starting temporarily..."
    systemctl start postgresql
fi

# Check if role exists
ROLE_EXISTS=$(su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${TARGET_USER}'\"" 2>/dev/null || true)
if [ "$ROLE_EXISTS" != "1" ]; then
    echo "Creating PostgreSQL role '${TARGET_USER}' with CREATEDB..."
    su - postgres -c "createuser --createdb --login '${TARGET_USER}'"
fi

# Check if database exists
DB_EXISTS=$(su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${TARGET_USER}'\"" 2>/dev/null || true)
if [ "$DB_EXISTS" != "1" ]; then
    echo "Creating PostgreSQL database '${TARGET_USER}'..."
    su - postgres -c "createdb -O '${TARGET_USER}' '${TARGET_USER}'"
fi

echo "PostgreSQL initialized for user '${TARGET_USER}' with peer authentication (no passwords)."
EOF
chmod +x "$DEST_BIN/alien-pg-init"

# 5. alien-dev-services (CLI + Zenity GUI)
cat > "$DEST_BIN/alien-dev-services" <<'EOF'
#!/usr/bin/env bash
# Alien OS — Dev Services Manager (PostgreSQL & MongoDB)
set -euo pipefail

# Detect persistence on live boot
check_persistence() {
    if [ ! -d /lib/live/mount/persistence ] && [ ! -d /run/live/persistence ] && grep -q "boot=live" /proc/cmdline 2>/dev/null; then
        return 1 # Live without persistence
    fi
    return 0 # Persistent or installed
}

get_pg_status() {
    if systemctl is-active --quiet postgresql; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

get_pg_boot() {
    if systemctl is-enabled --quiet postgresql 2>/dev/null; then
        echo "ENABLED"
    else
        echo "DISABLED"
    fi
}

get_mongo_status() {
    if systemctl is-active --quiet mongod; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

get_mongo_boot() {
    if systemctl is-enabled --quiet mongod 2>/dev/null; then
        echo "ENABLED"
    else
        echo "DISABLED"
    fi
}

show_cli_status() {
    echo "=========================================================="
    echo "               Alien OS Dev Services Status              "
    echo "=========================================================="
    if ! check_persistence; then
        echo "⚠️  WARNING: Running in LIVE mode without persistence!"
        echo "   Database data and configurations will be LOST on reboot."
        echo "=========================================================="
    fi
    echo "PostgreSQL:"
    echo "  Status:        $(get_pg_status)"
    echo "  Start at boot: $(get_pg_boot)"
    echo "  Connection:    postgresql://${USER:-alien}@localhost:5432/${USER:-alien}"
    echo "  CLI Command:   psql or pgcli"
    echo "----------------------------------------------------------"
    echo "MongoDB:"
    echo "  Status:        $(get_mongo_status)"
    echo "  Start at boot: $(get_mongo_boot)"
    echo "  Connection:    mongodb://127.0.0.1:27017/"
    echo "  CLI Command:   mongosh"
    echo "=========================================================="
}

run_gui() {
    while true; do
        PG_STAT="$(get_pg_status)"
        PG_BOOT="$(get_pg_boot)"
        MG_STAT="$(get_mongo_status)"
        MG_BOOT="$(get_mongo_boot)"

        WARN_TEXT=""
        if ! check_persistence; then
            WARN_TEXT="\n<span foreground='red' weight='bold'>⚠️ WARNING: Live session without persistence! Data will be lost on reboot.</span>\n"
        fi

        HEADER="<b>PostgreSQL:</b> ${PG_STAT} (Boot: ${PG_BOOT})\n<b>MongoDB:</b>    ${MG_STAT} (Boot: ${MG_BOOT})${WARN_TEXT}\nChoose an action:"

        ACTION=$(zenity --list --title="Alien Dev Services" \
            --text="$HEADER" \
            --column="ID" --column="Service Action" \
            "pg_toggle" "PostgreSQL: $([ "$PG_STAT" = "RUNNING" ] && echo "Stop" || echo "Start")" \
            "pg_boot"   "PostgreSQL: $([ "$PG_BOOT" = "ENABLED" ] && echo "Disable" || echo "Enable") Start at Boot" \
            "mg_toggle" "MongoDB:    $([ "$MG_STAT" = "RUNNING" ] && echo "Stop" || echo "Start")" \
            "mg_boot"   "MongoDB:    $([ "$MG_BOOT" = "ENABLED" ] && echo "Disable" || echo "Enable") Start at Boot" \
            "conn_info" "Show Connection Strings & Test Ping" \
            --width=520 --height=340 --hide-column=1 || true)

        if [ -z "$ACTION" ]; then
            break
        fi

        case "$ACTION" in
            pg_toggle)
                if [ "$PG_STAT" = "RUNNING" ]; then
                    pkexec systemctl stop postgresql
                else
                    pkexec systemctl start postgresql
                    # Ensure database role is initialized
                    pkexec /usr/bin/alien-pg-init "${USER:-alien}" || true
                fi
                ;;
            pg_boot)
                if [ "$PG_BOOT" = "ENABLED" ]; then
                    pkexec systemctl disable postgresql
                else
                    pkexec systemctl enable postgresql
                fi
                ;;
            mg_toggle)
                if [ "$MG_STAT" = "RUNNING" ]; then
                    pkexec systemctl stop mongod
                else
                    pkexec systemctl start mongod
                fi
                ;;
            mg_boot)
                if [ "$MG_BOOT" = "ENABLED" ]; then
                    pkexec systemctl disable mongod
                else
                    pkexec systemctl enable mongod
                fi
                ;;
            conn_info)
                PG_PING="PostgreSQL: Not Running"
                if [ "$(get_pg_status)" = "RUNNING" ]; then
                    PG_VER=$(su - "${USER:-alien}" -c "psql -tAc 'SELECT version();'" 2>/dev/null | head -1 || echo "Error connecting")
                    PG_PING="PostgreSQL Active:\n  $PG_VER"
                fi
                MG_PING="MongoDB: Not Running"
                if [ "$(get_mongo_status)" = "RUNNING" ]; then
                    MG_TEST=$(mongosh --quiet --eval "db.runCommand({ping:1}).ok" 2>/dev/null || echo "0")
                    if [ "$MG_TEST" = "1" ]; then
                        MG_PING="MongoDB Active (Ping 1 OK)"
                    else
                        MG_PING="MongoDB Error Connecting"
                    fi
                fi
                zenity --info --title="Dev Connection Strings" \
                    --text="<b>PostgreSQL:</b>\nURI: <code>postgresql://${USER:-alien}@localhost:5432/${USER:-alien}</code>\nCLI: <code>psql</code> or <code>pgcli</code>\nStatus: ${PG_PING}\n\n<b>MongoDB:</b>\nURI: <code>mongodb://127.0.0.1:27017/</code>\nCLI: <code>mongosh</code>\nStatus: ${MG_PING}" \
                    --width=500 || true
                ;;
        esac
    done
}

CMD="${1:-}"

case "$CMD" in
    status)
        show_cli_status
        ;;
    start)
        SERVICE="${2:-}"
        if [ "$SERVICE" = "postgresql" ] || [ "$SERVICE" = "postgres" ]; then
            pkexec systemctl start postgresql
            pkexec /usr/bin/alien-pg-init "${USER:-alien}" || true
            echo "PostgreSQL started."
        elif [ "$SERVICE" = "mongodb" ] || [ "$SERVICE" = "mongod" ]; then
            pkexec systemctl start mongod
            echo "MongoDB started."
        else
            echo "Usage: alien-dev-services start <postgresql|mongodb>"
            exit 1
        fi
        ;;
    stop)
        SERVICE="${2:-}"
        if [ "$SERVICE" = "postgresql" ] || [ "$SERVICE" = "postgres" ]; then
            pkexec systemctl stop postgresql
            echo "PostgreSQL stopped."
        elif [ "$SERVICE" = "mongodb" ] || [ "$SERVICE" = "mongod" ]; then
            pkexec systemctl stop mongod
            echo "MongoDB stopped."
        else
            echo "Usage: alien-dev-services stop <postgresql|mongodb>"
            exit 1
        fi
        ;;
    enable)
        SERVICE="${2:-}"
        if [ "$SERVICE" = "postgresql" ]; then
            pkexec systemctl enable postgresql
            echo "PostgreSQL enabled at boot."
        elif [ "$SERVICE" = "mongodb" ]; then
            pkexec systemctl enable mongod
            echo "MongoDB enabled at boot."
        fi
        ;;
    disable)
        SERVICE="${2:-}"
        if [ "$SERVICE" = "postgresql" ]; then
            pkexec systemctl disable postgresql
            echo "PostgreSQL disabled at boot."
        elif [ "$SERVICE" = "mongodb" ]; then
            pkexec systemctl disable mongod
            echo "MongoDB disabled at boot."
        fi
        ;;
    *)
        if [ -n "${DISPLAY:-}" ]; then
            run_gui
        else
            show_cli_status
        fi
        ;;
esac
EOF
chmod +x "$DEST_BIN/alien-dev-services"

# 6. Dev Services Desktop Entry
cat > "$DEST_APPS/alien-dev-services.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Dev Services
GenericName=Developer Services Manager
Comment=Manage PostgreSQL and MongoDB databases
Exec=alien-dev-services
Icon=preferences-system
Categories=Development;System;Settings;
StartupNotify=false
EOF

# 7. Chroot Hook for Developer Stack (/config/hooks/normal/0040-dev-stack-setup.hook.chroot)
cat > "$DEST_HOOKS/0040-dev-stack-setup.hook.chroot" <<'EOF'
#!/bin/sh
set -e

echo ">>> Setting up Developer Stack (PostgreSQL, MongoDB, VS Code)..."

# Ensure databases are disabled at boot
systemctl disable postgresql.service 2>/dev/null || true
systemctl disable postgresql@17-main.service 2>/dev/null || true
systemctl disable mongod.service 2>/dev/null || true

# Bind PostgreSQL to localhost only
for conf in /etc/postgresql/*/main/postgresql.conf; do
    if [ -f "$conf" ]; then
        sed -i "s/^#\?listen_addresses\s*=.*/listen_addresses = 'localhost'/" "$conf"
    fi
done

# Bind MongoDB to 127.0.0.1 and ensure data directory
if [ -f /etc/mongod.conf ]; then
    mkdir -p /var/lib/mongodb /var/log/mongodb
    if id mongodb >/dev/null 2>&1; then
        chown -R mongodb:mongodb /var/lib/mongodb /var/log/mongodb
    fi
fi

# Ensure /etc/skel/.vscode permissions
if [ -d /etc/skel/.vscode ]; then
    chmod 755 /etc/skel/.vscode
    chmod 644 /etc/skel/.vscode/extensions.json 2>/dev/null || true
fi

echo ">>> Developer Stack setup complete (services disabled by default)."
EOF
chmod +x "$DEST_HOOKS/0040-dev-stack-setup.hook.chroot"

echo "  - Preseeded Developer Stack configuration (PostgreSQL, MongoDB, VS Code, Dev Services)"
