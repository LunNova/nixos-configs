#!/usr/bin/env -S nix shell nixpkgs#parted -c bash
# shellcheck shell=bash

set -euo pipefail

# Examples, update before use
prefix="hisame_"
suffix="_2"
device=/dev/nvme1n1

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"

echo "ctrl-c now if this is not the expected target device, enter to continue with partitioning"
read -r -p "Press enter to continue"

parted -s -a optimal -- "$device" \
	mklabel gpt \
	mkpart "${prefix}esp${suffix}" fat32 1MiB 1GiB \
	set 1 esp on \
	mkpart "${prefix}persist${suffix}" btrfs 1GiB 100%

sync
sleep 1

mkfs.fat -F 32 "${device}p1" -n _esp
mkfs.btrfs -f "${device}p2" -R free-space-tree -L _persist

sync
sleep 1

mountdir="$(mktemp -d)"

mount -t btrfs -o defaults,ssd,nosuid,nodev,compress=zstd,noatime "${device}p2" "$mountdir"

btrfs subvolume create "$mountdir"/@persist
btrfs subvolume sync "$mountdir"

sleep 1

umount "$mountdir"
sync
sleep 1

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"
echo Done!
