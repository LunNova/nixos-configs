{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "lun-amaya-nixos";
    networking.hostId = "ad97aa3e";
    system.stateVersion = "21.11";

    hardware.cpu.amd.updateMicrocode = true;

    my.home-manager.enabled-users = [ "lun" ];

    users.mutableUsers = false;
    environment.etc =
      builtins.listToAttrs (map
        (name: { inherit name; value.source = "/nix/persist/etc/${name}"; })
        [
          "machine-id"
          "ssh/ssh_host_ed25519_key"
          "ssh/ssh_host_rsa_key"
        ]);
    fileSystems =
      {
        "/" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "mode=755" ]; };
        "/boot" = { device = "/dev/disk/by-partlabel/_esp"; fsType = "vfat"; options = [ "discard" "noatime" ]; };
        "/nix" = { device = "/dev/disk/by-partlabel/_nix"; fsType = "ext4"; options = [ "discard" "noatime" ]; };
        "/home" = { device = "/nix/persist/home"; noCheck = true; options = [ "bind" ]; };
        "/var/log" = { device = "/nix/persist/var/log"; noCheck = true; options = [ "bind" ]; };
      };
    swapDevices = [ ];
  };
}
