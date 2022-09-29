{ config, pkgs, lib, ... }:
let
  name = "hisame";
  swap = "/dev/disk/by-partlabel/hisame_swap";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" "noatime" "autodefrag" ];
  btrfsHddOpts = btrfsOpts ++ [ ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "discard=async" ];
in
{
  imports = [
  ];

  config = {
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "63d3399d2f2f65c96848f11d73082aef";
    system.stateVersion = "22.05";

    boot.kernelParams = [
      "mitigations=off"

      # I usually turn on iommu=pt and amd_iommu=force
      # for vm performance
      # but had some instability that might be caused by it

      # List amdgpu param docs
      #   modinfo amdgpu | grep "^parm:"
      # List amdgpu param current values and undocumented params
      #   nix shell pkgs#sysfsutils -c systool -vm amdgpu

      # runpm:PX runtime pm (2 = force enable with BAMACO, 1 = force enable with BACO, 0 = disable, -1 = auto) (int)
      "amdgpu.runpm=2"
      "amdgpu.dpm=0"
      "amdgpu.aspm=0"
      "amdgpu.bapm=0"

      # sched_policy:Scheduling policy (0 = HWS (Default), 1 = HWS without over-subscription, 2 = Non-HWS (Used for debugging only) (int)
      "amdgpu.sched_policy=1" # maybe workaround GPU driver crash with mixed graphics/compute loads
      "amdgpu.audio=0" # We never use display audio
      "amdgpu.ppfeaturemask=0xffffffff" # enable all powerplay features
      "amdgpu.gpu_recovery=2" # advanced TDR mode
      # reset_method:GPU reset method (-1 = auto (default), 0 = legacy, 1 = mode0, 2 = mode1, 3 = mode2, 4 = baco/bamaco) (int)
      "amdgpu.reset_method=4"

      # hw hwatchdog doesn't work on this platform
      "nmi_watchdog=0"
      "nowatchdog"

      # trust tsc, modern AMD platform
      "tsc=nowatchdog"

      # PCIE tinkering
      # "pcie_ports=native"
      # "pci=bfsort,assign-busses,realloc,nocrs"
      # "pcie_aspm=off"
    ];
    boot.plymouth.enable = lib.mkForce false;
    boot.kernelPatches = [{
      name = "idle-fix";
      patch = ./idle.patch;
    }];

    specialisation.no-ecc.configuration = {
      boot.kernelPatches = [{
        name = "amdgpu-no-ecc";
        patch = ./amdgpu-no-ecc.patch;
      }];
      boot.kernelParams = [
        "amdgpu.ras_enable=0"
      ];
    };

    # watchdog hardware doesn't work
    boot.blacklistedKernelModules = [ "sp5100_tco" ];

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod_latest;
    #lun.amd-mem-encrypt.enable = true;

    # Modulecan't load without "amd_pstate.shared_mem=1"
    # lun.amd-pstate.enable = true;
    lun.power-saving.enable = true;
    lun.efi-tools.enable = true;

    services.xserver.videoDrivers = [ "amdgpu" ];
    lun.ml = {
      enable = true;
      gpus = [ "amd" ];
    };
    hardware.opengl = {
      package = pkgs.lun.mesa.drivers;
      extraPackages = [
        pkgs.libglvnd
        pkgs.lun.mesa.drivers
        # Seems to perform worse but may be worth trying if ever run into vulkan issues
        # pkgs.amdvlk
      ];
      extraPackages32 = [
        pkgs.pkgsi686Linux.mesa.drivers
      ];
    };

    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;

    lun.home-assistant.enable = true;
    lun.wg-netns = {
      enable = true;

      privateKey = "/persist/mullvad/priv.key";
      peerPublicKey = "ctROwSybsU4cHsnGidKtbGYWRB2R17PFMMAqEHpsSm0=";
      endpointAddr = "198.54.133.82:51820";
      ip4 = "10.65.206.162/32";
      ip6 = "fc00:bbbb:bbbb:bb01::2:cea1/128";

      isolateServices = [ "transmission" ];
      forwardPorts = [ 9091 ];

      # dns = [ "10.64.0.1" ];
    };

    services.transmission = let downloadBase = "/persist/transmission"; in
      {
        enable = true;
        # group = "nas";

        settings = {
          download-dir = "${downloadBase}/default";
          incomplete-dir = "${downloadBase}/incomplete";

          peer-port = 45982;

          rpc-enabled = true;
          rpc-port = 9091;
          rpc-authentication-required = true;

          rpc-username = "lun";
          rpc-password = "nix-placeholder";

          # Proxied behind nginx.
          rpc-whitelist-enabled = false;
          rpc-whitelist = "127.0.0.1";

          verify-threads = 4;
        };
      };
    networking.firewall = {
      allowedTCPPorts = [ 45982 ];
      allowedUDPPorts = [ 45982 ];
    };

    lun.persistence.enable = true;
    lun.persistence.dirs = [
      "/home"
      "/var/log"
      "/nix"
      "/var/lib/transmission"
    ];
    users.users.${config.services.borgbackup.repos.uknas.user}.home = "/home/borg";
    services.borgbackup.repos = {
      uknas = {
        authorizedKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC46P3Z/EfSiZJ7xtvHWJFWDBfRH76F9EeDsqbNdTgtl1UxlmckzpCKJgZuiCq4HBQQS2D6sFHq/iVGT5mdq+SQOLZMns3gxH+wedW+XgSGScK35GV7eJjK2EASYzGWEdC/6fhARBpsMcE1cGmLckTeuRHoVGhTig/rOxXCPTPYMaTTLszPkw2D04qut4WD8IuKJegClerbyW2MV4kZdP/kIVg7gGB+jivTTtQsubgSdjw5xLS9OTK0X11f7LSpn6CqC03etnTJUe62D5j5dBLtFT55KLIDGPr86oeFnKF7/ykVSAlhmCly19eJGpG3TqZZaHrqBBtQ9iRsvgavmGiz uknas"
        ];
        path = "/mnt/_nas0/borg/uknas";
      };
    };
    services.beesd.filesystems = {
      persist = {
        spec = "PARTLABEL=${name}_persist_2";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "2.0" ];
      };
      scratch = {
        spec = "PARTLABEL=${name}_scratch";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "2.0" ];
      };
    };
    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };
      "/boot" = lib.mkForce {
        device = "/dev/disk/by-partlabel/${name}_esp_2";
        fsType = "vfat";
        neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = lib.mkForce {
        device = "/dev/disk/by-partlabel/${name}_persist_2";
        fsType = "btrfs";
        neededForBoot = true;
        options = btrfsSsdOpts ++ [ "subvol=@persist" "nodev" "nosuid" ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        neededForBoot = true;
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=32G" ];
      };
      "/mnt/_nas0" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/_nas0";
        neededForBoot = false;
        options = btrfsHddOpts ++ [ "nofail" ];
      };
      "/mnt/scratch" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/hisame_scratch";
        neededForBoot = false;
        options = btrfsSsdOpts ++ [ "nofail" "subvol=@scratch" ];
      };
    };
    swapDevices = lib.mkForce [
      { device = swap; }
    ];
    boot.resumeDevice = swap;
  };
}
