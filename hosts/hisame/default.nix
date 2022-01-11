{ config, pkgs, lib, nixos-hardware-modules-path, ... }:
let
  name = "hisame";
  swap = "/dev/disk/by-partlabel/_swap";
in
{
  imports = [
    "${nixos-hardware-modules-path}/common/gpu/amd"
  ];

  config = {
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "63d3399d2f2f65c96848f11d73082aef";
    system.stateVersion = "21.11";

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod;

    hardware.cpu.amd.updateMicrocode = true;

    my.home-manager.enabled-users = [ "lun" ];

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
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=32G" ];
      };
    };
    swapDevices = [{
      device = swap;
    }];
    boot.resumeDevice = swap;
  };
}
