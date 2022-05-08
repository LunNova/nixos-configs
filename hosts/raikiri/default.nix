{ config, pkgs, lib, nixos-hardware-modules-path, ... }:
let
  name = "raikiri";
  swap = "/dev/disk/by-partlabel/_swap";
in
{
  imports = [
  ];

  config = {
    networking.hostName = "mmk-${name}-nixos";
    sconfig.machineId = "cb26ad93b8a7b58bb481b6fc3a90f12b";
    system.stateVersion = "22.05";

    boot.kernelParams = [
      "mitigations=off"
      "quiet"
      "splash"
    ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod;

    services.xserver.videoDrivers = [ "nvidia" ];
    lun.ml = {
      enable = true;
      gpus = [ "nvidia" ];
    };

    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;
    my.home-manager.enabled-users = [ "lun" "mmk" ];

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
