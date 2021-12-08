{ config, pkgs, lib, ... }:
{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false; # we install refind after
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
