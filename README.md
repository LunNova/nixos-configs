# Lun (and family) nixos-configs

Our initial attempts at using NixOS.

- [Hosts](hosts/)
- [Modules](modules/)
- [Packages](packages/)
- [Users](users/)

# Fresh install

Similar to [tmpfs on root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/).

Set up persist and EFI partitions, then use [install.sh](scripts/install/install.sh).

The install script sets up rEFInd too as it makes managing multi-os systems and recovering from boot issues easier than plain systemd boot.
