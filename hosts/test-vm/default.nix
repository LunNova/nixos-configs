{ lib, ... }:
let
  name = "test";
in
{
  config = {
    sconfig.machineId = "2e96a6dde38fec8bed7dd1c0d88fa7c5";
    system.stateVersion = "23.05";

    hardware.cpu.amd.updateMicrocode = true;

    lun.persistence.enable = true;
    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "defaults" "size=2G" "mode=755" ];
      };
      "/boot" = {
        device = "/dev/disk/by-partlabel/${name}_esp";
        fsType = "vfat";
        neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = {
        device = "/dev/disk/by-partlabel/${name}_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@persist" "nodev" "nosuid" ];
      };
      "/nix" = {
        neededForBoot = true;
      };
    };
    swapDevices = lib.mkForce [ ];
    boot.resumeDevice = "";
  };
}
