{ config, pkgs, lib, nixos-hardware-modules-path, ... }:
let
  name = "hisame";
  swap = "/dev/disk/by-partlabel/_swap";
  btrfsOpts = [ "rw" "noatime" ];
in
{
  imports = [
  ];

  config = {
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "63d3399d2f2f65c96848f11d73082aef";
    system.stateVersion = "21.11";

    boot.kernelParams = [
      "mitigations=off"
      "quiet"
      "splash"
    ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    lun.amd-mem-encrypt.enable = true;

    lun.efi-tools.enable = true;

    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];
    lun.ml = {
      enable = true;
      gpus = [ "amd" ];
    };
    hardware.opengl = {
      extraPackages = [
        pkgs.libglvnd
        pkgs.mesa.drivers
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
      "/boot" = {
        device = "/dev/disk/by-partlabel/_esp";
        fsType = "vfat";
        neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = {
        device = "/dev/disk/by-partlabel/${name}_persist";
        fsType = "ext4";
        neededForBoot = true;
        options = [ "discard" "noatime" ];
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
        options = btrfsOpts ++ [ "nofail" ];
      };
    };
    swapDevices = [{
      device = swap;
    }];
    boot.resumeDevice = swap;
  };
}
