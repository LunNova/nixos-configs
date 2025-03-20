{ flakeArgs, lib, pkgs, ... }:
let
  name = "aoame";
in
{
  imports = [
    flakeArgs.x1e-nixos-config.nixosModules.x1e
    flakeArgs.disko.nixosModules.disko
    flakeArgs.lanzaboote.nixosModules.lanzaboote
    ./disk-config.nix
  ];
  config = {
    networking.hostName = "lun-${name}";
    sconfig.machineId = "829c75bd19699f20f80e5b3fc80f7310";
    system.stateVersion = "24.11";

    boot.loader.systemd-boot.consoleMode = "max";
    console.font = lib.mkForce "ter-v12n";
    console.packages = [ pkgs.terminus_font ];
    hardware.deviceTree.name = "qcom/x1e80100-lenovo-yoga-slim7x.dtb";
    nix.channel.enable = false;
    boot.loader.systemd-boot = {
      enable = true;
      # Limit space in EFI partition
      configurationLimit = 10;
    };
    boot.initrd.systemd = {
      enable = true;

      # This is not secure, but it makes diagnosing errors easier.
      emergencyAccess = true;
    };

    hardware.enableRedistributableFirmware = true;

    networking.networkmanager = {
      enable = true;
      plugins = lib.mkForce [ ];
    };

    hardware.bluetooth.enable = true;
  };
}
