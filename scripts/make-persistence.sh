#!/usr/bin/env bash
# Alien — Create a persistence partition on a USB stick.
# This script creates an ext4 partition labeled 'persistence' and sets it up.
# WARNING: Always double check the device path!

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo $0 <device>"
  exit 1
fi

DEVICE="${1:-}"

if [ -z "$DEVICE" ]; then
  echo "Usage: sudo $0 <device>"
  echo "Example: sudo $0 /dev/sdb"
  echo ""
  echo "Available disks:"
  lsblk -d -p -o NAME,SIZE,MODEL,TRAN | grep usb || true
  exit 1
fi

if [[ ! -b "$DEVICE" ]]; then
  echo "Error: $DEVICE is not a valid block device."
  exit 1
fi

echo "=========================================================================="
echo "                         !!! DANGER !!!"
echo "=========================================================================="
echo "You are about to modify the partition table on: $DEVICE"
lsblk -p -o NAME,SIZE,MODEL,FSTYPE,LABEL "$DEVICE"
echo ""
echo "This will create a new partition at the end of the drive for persistence."
echo "If this is your main hard drive, DO NOT PROCEED."
echo ""
read -p "Type 'I AM SURE' to proceed: " CONFIRM

if [ "$CONFIRM" != "I AM SURE" ]; then
  echo "Aborted."
  exit 1
fi

echo ">>> Creating a new partition for persistence..."
# We use parted to create an ext4 partition using the remaining space
parted -s "$DEVICE" mkpart primary ext4 100% 100% || true

# Wait for kernel to re-read partition table
partprobe "$DEVICE"
sleep 2

# Identify the new partition (should be the highest numbered partition on the device)
PART="$(lsblk -l -p -o NAME "$DEVICE" | grep -E "^${DEVICE}[0-9p]+$" | sort -V | tail -n 1)"

if [ -z "$PART" ]; then
  echo "Error: Could not determine the new partition."
  exit 1
fi

echo ">>> Formatting $PART to ext4..."
mkfs.ext4 -L persistence "$PART"

echo ">>> Setting up persistence configuration..."
mkdir -p /mnt/alien-persistence
mount "$PART" /mnt/alien-persistence

# Create persistence.conf
echo "/ union" > /mnt/alien-persistence/persistence.conf

umount /mnt/alien-persistence
rm -rf /mnt/alien-persistence

echo "=========================================================================="
echo "SUCCESS: Persistence partition created on $PART."
echo "To use it, boot Alien Lite and choose the persistence option in GRUB."
echo "=========================================================================="
