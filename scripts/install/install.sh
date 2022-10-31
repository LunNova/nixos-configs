#!/usr/bin/env bash
set -xeuo pipefail
IFS="$(printf "\n")"

# edit these fields
NAME=router
HOSTNAME="$NAME-nixos"

BOOT_PARTITION=/dev/disk/by-partlabel/"$NAME"_esp
PERSIST_PARTITION=/dev/disk/by-partlabel/"$NAME"_persist
FLAKE=github:LunNova/nixos-configs/dev#$HOSTNAME

mount -t tmpfs none /mnt

mkdir -p /mnt/{boot,persist}

mount $BOOT_PARTITION /mnt/boot
mount "$PERSIST_PARTITION" -o defaults,ssd,nosuid,nodev,compress=zstd,noatime,subvol=@persist /mnt/persist

mkdir -p /mnt/{boot,persist,home,nix,var/log} /mnt/persist/{home,nix,var/log,etc/ssh,root}

for dir in $(nix eval --raw "$FLAKE#nixosConfigurations.$HOSTNAME.config.lun.persistence.dirs_for_shell_script"); do
	mkdir "/mnt$dir"
	mkdir "/mnt/persist$dir"
	mount -o bind "/mnt/persist$dir" "/mnt$dir"
done

mount -o bind /mnt/persist/nix /mnt/nix
mount -o bind /mnt/persist/home /mnt/home
mount -o bind /mnt/persist/var/log /mnt/var/log

# Install nixos:
nix-shell -p git nixFlakes --run "nixos-install --impure --no-root-passwd --root /mnt --flake $FLAKE"
# Install refind efi boot manager
nix-shell -p efibootmgr refind --run "refind-install --root /mnt"
