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
        theme = "breeze";
        logo = lun.assets.images.crescent_moon;
      };
    };
  };
}
