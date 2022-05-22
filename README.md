# Lun (and family) nixos-configs

Our initial attempts at using NixOS.

- [Users](users/)
- [Modules](modules/)
- [Hosts](hosts/)

# Fresh install

Similar to [tmpfs on root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/).

Set up persist and EFI partitions, then use [install.sh](scripts/install.sh).

The install script sets up rEFInd too as it makes managing multi-os systems and recovering from boot issues easier than plain systemd boot.
