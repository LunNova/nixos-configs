# Lun (and family) nixos-configs

Our initial attempts at using NixOS.

- [Users](users/)
- [Modules](modules/)
- [Hosts](hosts/)

# Fresh install

Similar to [tmpfs on root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/).

Set up persist and EFI partitions, then:

```
#!/usr/bin/env bash
set -xeuo pipefail

BOOT_PARTITION=/dev/disk/by-partlabel/_esp
PERSIST_PARTITION=/dev/disk/by-partlabel/hostname_persist
FLAKE=github:TransLunarInjection/nixos-configs/dev#hostname

mount -t tmpfs none /mnt

mkdir -p /mnt/{boot,persist}

mount $BOOT_PARTITION /mnt/boot
mount $PERSIST_PARTITION /mnt/persist

mkdir -p /mnt/{boot,persist,home,nix,var/log} /mnt/persist/{home,nix,var/log}

mount -o bind /mnt/persist/nix /mnt/nix
mount -o bind /mnt/persist/home /mnt/home
mount -o bind /mnt/persist/var/log /mnt/var/log

# Install nixos:
nix-shell -p git nixFlakes --run "nixos-install --impure --no-root-passwd --root /mnt --flake $FLAKE"
# Install refind efi boot manager
nix-shell -p efibootmgr refind --run "refind-install --root /mnt"
```
