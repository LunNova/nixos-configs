#!/usr/bin/env -S nix --extra-experimental-features "nix-command flakes" shell nixpkgs#parted -c bash
# shellcheck shell=bash

set -euo pipefail

# Examples, update before use
prefix="router_"
#swap_size="0"
swap_size="32GiB"
suffix="_2"
device=/dev/nvme0n1
partprefix="p"

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"

echo "ctrl-c now if this is not the expected target device, enter to continue with partitioning"
read -r -p "Press enter to continue"
read -r -p "Press enter again to continue"

blkdiscard -f -s "$device" || blkdiscard -f "$device"

sync
sleep 1

if [ "z$swap_size" = "z0" ]; then
	echo "not making swap part"
	datapart="${device}${partprefix}2"
	parted -s -a optimal -- "$device" \
		mklabel gpt \
		mkpart "${prefix}esp${suffix}" fat32 1MiB 1GiB \
		set 1 esp on \
		mkpart "${prefix}persist${suffix}" btrfs 1GiB 100%
else
	datapart="${device}${partprefix}3"
	parted -s -a optimal -- "$device" \
		mklabel gpt \
		mkpart "${prefix}esp${suffix}" fat32 1MiB 1GiB \
		set 1 esp on \
		mkpart "${prefix}swap${suffix}" linux-swap 1GiB "$swap_size" \
		mkpart "${prefix}persist${suffix}" btrfs "$swap_size" 100%
fi

sync
sleep 1

mkfs.fat -F 32 "${device}${partprefix}1" -n _esp
sync

if [ "z$swap_size" != "z0" ]; then
	mkswap /dev/disk/by-partlabel/"${prefix}swap${suffix}" -L _swap
	sync
fi

mkfs.btrfs -f "${datapart}" -R free-space-tree -L _persist
sync

sync
sleep 1

mountdir="$(mktemp -d)"

mount -t btrfs -o defaults,ssd,nosuid,nodev,compress=zstd,noatime "${datapart}" "$mountdir"

btrfs subvolume create "$mountdir"/@persist
btrfs subvolume sync "$mountdir"

sleep 1

umount "$mountdir"
sync
sleep 1

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"
echo Done!
