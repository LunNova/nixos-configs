# Lun (and family) nixos-configs

Configs for my devices, home devices, shared devices.  
Started out as a fairly normal home setup; escalated into a full GPGPU validation lab at some point and it's too late to stop.

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
- `hisame`: A fast desktop with an RTX 4090 for CUDA ML validation and gfx1036 RDNA2 iGPU for ROCm validation. The name means «freezing rain, sleet».
- `shigure`: A desktop with a 7900XTX for RDNA 3 ML validation. The name means «late autumn rain, cold drizzle».
- `hoshitsuki`: A CPU/inference desktop with 5950x 16c32t CPU and 2x32GB W6800 PRO (RDNA2) GPUs. The name could be interpreted as «starlit moon».
- `tsukiakari`: A CPU/inference server with an EPYC 7V13 64-core, 128-thread CPU and 6x32GB Instinct MI100 GPUs for CDNA1 testing. The name means «moonlight».
- `tsukikage`: Similar to `tsukiakari` but Instinct MI210, for CDNA2 testing. The name means «moonlight shadow».
- `murasame`: WIP. Transiently available and external, unlike the other lab devices. The name means «passing shower, sudden rain».  Typical deployment targets are nodes with: Instinct MI35⌷X for CDNA4 testing, MI300⌷ for CDNA3 testing. Thanks hotaisle.xyz and cloudrift.ai!
- `kirisame`: ASUS PN50 mini-PC. Always-on services host. The name means «misty rain».
- `router`: HP t740 thin client with SFP+ PCIe NIC. 
- `builder`: minimal testcase with disko for image building, not deployed to any machine.

## Networking

Tailscale is *amazing* and just works™. Only complicated setup is `router` which handles both services and NAT and firewalling.  
LAN has an Arista DCS-7050SX-64 as backbone switch and a messy pile of slower switches for PoE devices (APs, NVR etc).

## Storage

Primary network storage is 24TiB of spinning rust on `router`.  
`tsukiakari` and `tsukikage` have around 100TiB of flash between them exclusively for ML workloads. May one day figure out how to do good distributed storage.
`hisame` has an unholy array of smaller SSDs as my primary workstation, and they're always getting full. I have a bit of a data hoarding problem.

# Fresh install

Similar to [tmpfs on root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/).

Set up persist and EFI partitions (at least 1GB for EFI!), then use [install.sh](scripts/install/install.sh).

The install script sets up rEFInd too as it makes managing multi-os systems and recovering from boot issues easier than plain systemd boot.
