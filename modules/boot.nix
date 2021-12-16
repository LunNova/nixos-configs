{ config, pkgs, lib, ... }:
{
  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = false;
      };
    };
  };
}
