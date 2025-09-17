{ config, flakeArgs, pkgs, lib, ... }:
let
  name = "builder";
  swap = null; #"/dev/disk/by-partlabel/${name}_swap";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" "noatime" ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "discard=async" ];
in
{
  imports = [
    ./disks.nix
    flakeArgs.disko.nixosModules.disko
  ];

  config = {
    networking.hostName = "${name}-nixos";
    sconfig.machineId = "91f4ea50707df31026b6c8894e28d509";
    system.stateVersion = "24.05";

    hardware.graphics.extraPackages = with pkgs; [
      amdvlk
      vulkan-loader
    ];

    boot.kernelParams = [
      "nosplash"
      # 10s timeout for all operations (otherwise compute defaults to 60s)
      "amdgpu.lockup_timeout=10000,10000,10000,10000"
      "amdgpu.runpm=0"
    ];
    environment.systemPackages = [
      pkgs.linuxPackages_latest.cpupower
      pkgs.dmidecode
    ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    lun.efi-tools.enable = true;
    services.nscd.enableNsncd = true;
    networking.firewall.allowedTCPPorts = [ 5000 5001 8000 8080 8081 ];
    programs.nix-ld.enable = true;

    systemd.defaultUnit = lib.mkForce "multi-user.target";
    boot.plymouth.enable = lib.mkForce false;
    services.xserver.autorun = false;
    services.power-profiles-daemon.enable = true;
    lun.amd-pstate.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];
    lun.ml = {
      enable = true;
      gpus = [ "amd" ];
    };
    lun.profiles = {
      server = true;
      personal = false;
      gaming = false;
      graphical = false;
    };
    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;
    my.home-manager.enabled-users = [ "lun" ];
    system.forbiddenDependenciesRegexes = [
      "kwin"
      "mutter"
    ];

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
        # neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = {
        device = "/dev/disk/by-partlabel/_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@persist" ] ++ btrfsSsdOpts;
      };
      "/nix" = lib.mkForce {
        device = "/dev/disk/by-partlabel/_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@nix" ] ++ btrfsSsdOpts;
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        neededForBoot = true;
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=50G" ];
      };
    };
    swapDevices = lib.optionals (swap != null) [{
      device = swap;
    }];
    boot.resumeDevice = if (swap != null) then swap else "";
  };
}
