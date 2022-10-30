#!/usr/bin/env -S nix shell nixpkgs#parted -c bash
# shellcheck shell=bash

# Partition a scratch drive for swap at the start and a big btrfs for the rest

set -euo pipefail

# Examples, update before use
type="bigscratch"
prefix="hisame_"
suffix=""
swap_size="0"
#swap_size="256GiB"
device=/dev/sdc
partprefix=""

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"

echo "ctrl-c now if this is not the expected target device, enter to continue with partitioning"
read -r -p "Press enter to continue"
read -r -p "Press enter again to continue"

blkdiscard -f -s "$device" || blkdiscard -f "$device"

sync
sleep 1

if [ "z$swap_size" = "z0" ]; then
	echo "not making swap part"
	datapart="${device}${partprefix}1"
	parted -s -a optimal -- "$device" \
		mklabel gpt \
		mkpart "${prefix}${type}${suffix}" btrfs 1MiB 100%
else
	datapart="${device}${partprefix}2"
	parted -s -a optimal -- "$device" \
		mklabel gpt \
		mkpart "${prefix}swap${suffix}" linux-swap 1MiB "$swap_size" \
		mkpart "${prefix}${type}${suffix}" btrfs "$swap_size" 100%
fi

sync
sleep 1

if [ "z$swap_size" != "z0" ]; then
	mkswap /dev/disk/by-partlabel/"${prefix}swap${suffix}" -L _swap
fi
mkfs.btrfs -f "${datapart}" -R free-space-tree -L _${type}

sync
sleep 1

mountdir="$(mktemp -d)"

mount -t btrfs -o defaults,ssd,nosuid,nodev,compress=zstd,noatime "${datapart}" "$mountdir"

btrfs subvolume create "$mountdir"/@main
btrfs subvolume sync "$mountdir"

sleep 1

umount "$mountdir"
sync
sleep 1

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"
echo Done!
