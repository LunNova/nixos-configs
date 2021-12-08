Our initial attempts at using NixOS. I'd advise against looking at this config for examples of how to do things unless you can't find anywhere else doing it,
because it is likely incorrect.

References looked at for how the fuck to do this:

Relative paths for config: https://github.com/MatthewCroughan/nixcfg/blob/d577d164eadc777b91db423e59b4ae8b26853fc6/flake.nix#L60

Various flake things: https://github.com/Icy-Thought/Snowflake

https://gitlab.com/hlissner/dotfiles/-/tree/master

# Fresh install

Set up partitions for new system and mount under /mnt.

```
mkdir -p /mnt/{boot,persist,home}

mount /dev/disk/by-partlabel/_esp /mnt/boot
mount /dev/disk/by-partlabel/hostname_persist /mnt/persist

# Install nixos:
nix-shell -p git nixFlakes --run "nixos-install --no-root-passwd --root /mnt --flake github:TransLunarInjection/nixos-configs#hostname"
# Install refind efi boot manager
nix-shell -p efibootmgr --run "refind-install --root /mnt"
```
