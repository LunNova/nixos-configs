{ lun, pkgs, ... }:
{
  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = false;
      };

      plymouth = {
        enable = true;
        logo = lun.assets.images.crescent_moon_100x100;
      };
    };
  };
}
