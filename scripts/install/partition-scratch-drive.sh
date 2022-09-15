#!/usr/bin/env -S nix shell nixpkgs#parted -c bash
# shellcheck shell=bash

# Partition a scratch drive for swap at the start and a big btrfs for the rest

set -euo pipefail

# Examples, update before use
prefix="hisame_"
suffix=""
swap_size="256GiB"
device=/dev/nvme0n1

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"

echo "ctrl-c now if this is not the expected target device, enter to continue with partitioning"
read -r -p "Press enter to continue"
read -r -p "Press enter again to continue"

blkdiscard -f -s "$device" || blkdiscard -f "$device"

sync
sleep 1

parted -s -a optimal -- "$device" \
	mklabel gpt \
	mkpart "${prefix}swap${suffix}" linux-swap 1MiB "$swap_size" \
	set 1 esp on \
	mkpart "${prefix}scratch${suffix}" btrfs "$swap_size" 100%

sync
sleep 1

mkswap /dev/disk/by-partlabel/"${prefix}swap${suffix}" -L _swap
mkfs.btrfs -f "${device}p2" -R free-space-tree -L _scratch

sync
sleep 1

mountdir="$(mktemp -d)"

mount -t btrfs -o defaults,ssd,nosuid,nodev,compress=zstd,noatime "${device}p2" "$mountdir"

btrfs subvolume create "$mountdir"/@scratch
btrfs subvolume sync "$mountdir"

sleep 1

umount "$mountdir"
sync
sleep 1

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"
echo Done!
