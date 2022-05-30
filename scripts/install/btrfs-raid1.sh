#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#parted -c bash
# shellcheck shell=bash
set -e

dryrun=
if [ z"$1" = zdry ]; then
  dryrun="echo"
else
  set -x
fi
#can do raid1c3 or raid1c4 if using more drives
type=raid1
fsname=_nas0
# edit this to target drives
drives="/dev/sdb /dev/sdc"
subvolumes="main borg"
$dryrun sync
$dryrun udevadm settle
for drive in $drives; do
  $dryrun dd if=/dev/zero of="$drive" bs=4096 count=4096
  $dryrun wipefs -a "$drive"
  $dryrun parted "$drive" mklabel gpt
  $dryrun parted -a optimal -- "$drive" mkpart $fsname btrfs 0% 100%
  $dryrun parted "$drive" set 1 raid on
done
$dryrun sync
$dryrun udevadm settle
# shellcheck disable=SC2206 # splitting intended
parts_ar=($drives)
parts_ar=("${parts_ar[@]/%/1}")
parts="${parts_ar[*]}"
first=$(echo "$parts" | cut -d " " -f 1)
$dryrun mkfs.btrfs -L $fsname -d "$type" -m "$type" -f "${parts_ar[@]}"
$dryrun sync
$dryrun udevadm settle
$dryrun mkdir -p /mnt/$fsname
$dryrun mount "$first" /mnt/$fsname
for subvolume in $subvolumes; do
  $dryrun btrfs subvolume create /mnt/$fsname/"$subvolume"
  $dryrun btrfs property set /mnt/$fsname/"$subvolume" compression zstd
done
