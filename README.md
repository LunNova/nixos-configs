Our initial attempts at using NixOS. I'd advise against looking at this config for examples of how to do things unless you can't find anywhere else doing it,
because it is likely incorrect.

References looked at for how the fuck to do this:

Relative paths for config: https://github.com/MatthewCroughan/nixcfg/blob/d577d164eadc777b91db423e59b4ae8b26853fc6/flake.nix#L60

Various flake things: https://github.com/Icy-Thought/Snowflake

https://gitlab.com/hlissner/dotfiles/-/tree/master

Sway setup https://github.com/lovesegfault/nix-config

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
