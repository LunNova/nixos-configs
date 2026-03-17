# Lun (and family) nixos-configs

Our initial attempts at using NixOS.

- [Hosts](hosts/#readme)
- [Modules](modules/#readme)
- [Packages](packages/#readme)
- [Users](users/#readme)

# Hosts

This folder contains information about our various hosts, mostly named after a Japanese word related to rain or moonlight except sometimes not.

## Host List

- `amayadori`: A low-power laptop. The name means «shelter from rain».
- `aoame`: A low-power laptop. The name means «blue rain».
- `kosame`: A fast laptop. The name means «light rain».
- `hisame`: A fast desktop with an RTX 4090 for CUDA ML validation. The name means «freezing rain, sleet».
- `shigure`: A desktop with a 7900XTX for RDNA 3 ML validation. The name means «late autumn rain, cold drizzle».
- `hoshitsuki`: A CPU/inference desktop with 5950x 16c32t CPU and 2x32GB VRAM GPUs. The name could be interpreted as «starlit moon».
- `tsukiakari`: A CPU/inference server with an EPYC 7V13 64-core, 128-thread CPU and 6x32GB Instinct MI100 GPUs for CDNA1 testing. The name means «moonlight».
- `tsukikage`: Similar to `tsukiakari` but Instinct MI210, for CDNA2 testing. The name means «moonlight shadow».
- `router`: HP t740 thin client with SFP+ PCIe NIC.
- `builder`: minimal testcase with disko for image building, not deployed to any machine.

# Fresh install

Similar to [tmpfs on root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/).

Set up persist and EFI partitions (at least 1GB for EFI!), then use [install.sh](scripts/install/install.sh).

The install script sets up rEFInd too as it makes managing multi-os systems and recovering from boot issues easier than plain systemd boot.
