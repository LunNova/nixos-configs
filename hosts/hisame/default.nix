{ config, pkgs, lib, ... }:
let name = "hisame"; in
{
  config = {
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "63d3399d2f2f65c96848f11d73082aef";
    system.stateVersion = "21.11";

    hardware.cpu.amd.updateMicrocode = true;
    services.xserver.videoDrivers = [ "amdgpu" ];

    boot.kernelParams = [ "boot.shell_on_fail" "boot.trace" ];

    my.home-manager.enabled-users = [ "lun" ];

    users.mutableUsers = false;
    environment.etc =
      builtins.listToAttrs (map
        (name: { inherit name; value.source = "/persist/etc/${name}"; })
        [
          "ssh/ssh_host_ed25519_key"
          "ssh/ssh_host_rsa_key"
        ]);
    fileSystems =
      {
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
    swapDevices = [ ];
  };
}
