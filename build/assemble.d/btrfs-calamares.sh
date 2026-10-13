#!/usr/bin/env bash
# Alien — Btrfs Layout, Snapper Configuration & Calamares Installer
set -euo pipefail

# 1. Calamares Partitioning & Mount Config
DEST_CAL_MODS="$WORK/config/includes.chroot/etc/calamares/modules"
mkdir -p "$DEST_CAL_MODS"

# Configure partition.conf to default to Btrfs with standard subvolumes
cat > "$DEST_CAL_MODS/partition.conf" <<'EOF'
# Alien OS Btrfs Layout & Partition Defaults
defaultFileSystemType: "btrfs"
availableFileSystemTypes:
  - "btrfs"
  - "ext4"

btrfsSubvolumes:
  - mountPoint: /
    subvolume: /@
  - mountPoint: /home
    subvolume: /@home
  - mountPoint: /.snapshots
    subvolume: /@snapshots
  - mountPoint: /var/log
    subvolume: /@var_log
  - mountPoint: /var/cache
    subvolume: /@var_cache

enableLuksAutomatedPartitioning: true
initialPartitioningChoice: erase
EOF

# Configure mount options in fstab.conf
cat > "$DEST_CAL_MODS/fstab.conf" <<'EOF'
# Alien OS Fstab & Mount Options
mountOptions:
  default: defaults,noatime
  btrfs: defaults,noatime,compress=zstd:1,space_cache=v2,discard=async
  ext4: defaults,noatime
  vfat: defaults,umask=0077
ssdMountOptions:
  btrfs: defaults,noatime,compress=zstd:1,space_cache=v2,discard=async
EOF

# 2. Snapper Default Configuration
DEST_SNAPPER="$WORK/config/includes.chroot/etc/snapper/configs"
mkdir -p "$DEST_SNAPPER"
cat > "$DEST_SNAPPER/root" <<'EOF'
# Snapper configuration for root filesystem on Alien OS
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS="sudo"
SYNC_ACL="no"

BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="20"
NUMBER_LIMIT_IMPORTANT="10"

TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
EOF

# Register config in /etc/default/snapper
mkdir -p "$WORK/config/includes.chroot/etc/default"
cat > "$WORK/config/includes.chroot/etc/default/snapper" <<'EOF'
SNAPPER_CONFIGS="root"
EOF

# 3. APT Pre/Post Snapshot Hook
DEST_APT_CONF="$WORK/config/includes.chroot/etc/apt/apt.conf.d"
mkdir -p "$DEST_APT_CONF"
cat > "$DEST_APT_CONF/80-alien-snapper" <<'EOF'
// Automatic Snapper pre/post snapshots for apt transactions
DPkg::Pre-Invoke {
  "if [ -x /usr/bin/snapper ] && [ -d /.snapshots ]; then /usr/bin/snapper create -t pre -p -c number -d 'Before apt transaction' > /var/tmp/snapper-apt-pre.id 2>/dev/null || true; fi";
};
DPkg::Post-Invoke {
  "if [ -x /usr/bin/snapper ] && [ -f /var/tmp/snapper-apt-pre.id ]; then /usr/bin/snapper create -t post --pre-number=$(cat /var/tmp/snapper-apt-pre.id) -c number -d 'After apt transaction' 2>/dev/null || true; rm -f /var/tmp/snapper-apt-pre.id; if [ -x /etc/grub.d/41_snapshots-btrfs ]; then update-grub 2>/dev/null || true; fi; fi";
};
EOF

# 4. GRUB Btrfs Integration Script (/etc/grub.d/41_snapshots-btrfs)
DEST_GRUB_D="$WORK/config/includes.chroot/etc/grub.d"
mkdir -p "$DEST_GRUB_D"
cat > "$DEST_GRUB_D/41_snapshots-btrfs" <<'EOF'
#!/bin/sh
# Generate GRUB menu entries for Btrfs snapshots
set -e

if [ -d "/.snapshots" ] && [ -x "$(command -v btrfs)" ]; then
  root_uuid="${GRUB_DEVICE_UUID:-$(grub-probe --target=fs_uuid / 2>/dev/null || true)}"
  snapshots="$(find /.snapshots/*/snapshot -maxdepth 0 2>/dev/null | sort -V -r || true)"
  if [ -n "$snapshots" ] && [ -n "$root_uuid" ]; then
    echo "submenu 'Alien OS Snapshots & Rollbacks' --class snapshots --class recovery {"
    for snap in $snapshots; do
      num="$(basename "$(dirname "$snap")")"
      info_file="/.snapshots/$num/info.xml"
      desc="Snapshot #$num"
      if [ -f "$info_file" ]; then
        d="$(grep -oPm1 "(?<=<description>)[^<]+" "$info_file" 2>/dev/null || true)"
        [ -n "$d" ] && desc="$desc ($d)"
      fi
      echo "  menuentry 'Boot Snapshot: $desc' --class snapshot {"
      echo "    load_video"
      echo "    insmod gzio"
      echo "    insmod part_gpt"
      echo "    insmod btrfs"
      echo "    search --no-floppy --fs-uuid --set=root $root_uuid"
      echo "    linux /@snapshots/$num/snapshot/boot/vmlinuz root=UUID=$root_uuid rootflags=subvol=@snapshots/$num/snapshot ro systemd.volatile=overlay quiet splash"
      echo "    initrd /@snapshots/$num/snapshot/boot/initrd.img"
      echo "  }"
    done
    echo "}"
  fi
fi
EOF
chmod +x "$DEST_GRUB_D/41_snapshots-btrfs"

echo "  - Configured Calamares Btrfs layout, Snapper hooks, and grub-btrfs integration"
