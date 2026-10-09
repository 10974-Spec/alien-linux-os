#!/bin/bash
set -Eeuo pipefail

log() { echo -e "\033[1;34m>>>\033[0m $*"; }
warn() { echo -e "\033[1;33m!!! WARNING:\033[0m $*" >&2; }
die() { echo -e "\033[1;31m!!! ERROR:\033[0m $*" >&2; exit 1; }

confirm() {
    local msg="$1"
    read -r -p "$msg [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "This script must be run as root."
    fi
}
