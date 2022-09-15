{ config, pkgs, lib, ... }:
let
  name = "router";
  swap = "/dev/disk/by-partlabel/_swap";
in
{
  imports = [
  ];

  config = {
    networking.usePredictableInterfaceNames = false; # TODO: flip after setting everything up
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "62df49c6dd7668e60028ed7c7f8b009d";
    system.stateVersion = "22.05";

    boot.kernelParams = [
      "quiet"
      "splash"
    ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;

    lun.persistence.enable = true;
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
      "/nix" = {
        device = "/persist/nix";
        noCheck = true;
        fsType = "none";
        neededForBoot = true;
        options = [ "bind" ];
      };
      "/home" = {
        device = "/persist/home";
        noCheck = true;
        neededForBoot = true;
        options = [ "bind" ];
      };
      "/var/log" = {
        device = "/persist/var/log";
        noCheck = true;
        neededForBoot = true;
        options = [ "bind" ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        neededForBoot = true;
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=4G" ];
      };
    };
    swapDevices = [{
      device = swap;
    }];
    boot.resumeDevice = swap;
  };
}
