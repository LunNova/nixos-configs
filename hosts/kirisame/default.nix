{ flakeArgs, pkgs, lib, ... }:
let
  name = "kirisame";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "discard=async" ];
in
{
  imports = [
    ./disks.nix
    flakeArgs.disko.nixosModules.disko
    flakeArgs.celler.nixosModules.cellerd
  ];

  config = {
    networking.hostName = "${name}-nixos";
    sconfig.machineId = "b0d07991f20852e6d4efc4a4f184215c";
    system.stateVersion = "24.11";

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 25;
    boot.plymouth.enable = lib.mkForce false;
    lun.efi-tools.enable = true;

    hardware.cpu.amd.updateMicrocode = true;
    hardware.enableRedistributableFirmware = true;
    lun.amd-pstate.enable = true;

    services.upower.enable = true;
    services.tuned.enable = true;
    services.nscd.enableNsncd = true;
    systemd.defaultUnit = lib.mkForce "multi-user.target";
    services.xserver.autorun = false;

    lun.profiles = {
      server = true;
      personal = false;
      gaming = false;
      graphical = false;
    };
    system.forbiddenDependenciesRegexes = [
      "kwin"
      "mutter"
    ];

    users.mutableUsers = false;
    my.home-manager.enabled-users = [ "lun" ];

    networking.useNetworkd = true;
    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = lib.mkDefault true;

    zramSwap.enable = true;
    zramSwap.memoryPercent = 50;

    nix.settings.max-jobs = 4;
    nix.settings.cores = 0;

    lun.persistence.enable = true;
    lun.persistence.dirs = [
      "/home"
      "/var/log"
      "/var/lib/private/cellerd"
    ];

    services.cellerd = {
      enable = true;
      package = flakeArgs.celler.packages.${pkgs.system}.celler;
      environmentFile = "/persist/celler-env";
      settings = {
        listen = "[::]:8080";
        jwt = { };
        chunking = {
          nar-size-threshold = 65536;
          min-size = 16384;
          avg-size = 65536;
          max-size = 262144;
        };
        compression = {
          type = "zstd";
          level = 8;
        };
        garbage-collection = {
          interval = "12 hours";
          default-retention-period = "0s";
        };
      };
    };
    networking.firewall.allowedTCPPorts = [ 8080 ];

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
        device = "/dev/disk/by-partlabel/${name}_esp";
        fsType = "vfat";
        options = [ "discard" "noatime" ];
      };
      "/persist" = {
        device = "/dev/disk/by-partlabel/${name}_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@persist" "nodev" "nosuid" ] ++ btrfsSsdOpts;
      };
      "/nix" = lib.mkForce {
        device = "/dev/disk/by-partlabel/${name}_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@nix" ] ++ btrfsSsdOpts;
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        neededForBoot = true;
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=8G" ];
      };
    };
  };
}
