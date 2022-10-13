{ lun, pkgs, lib, ... }:
{
  config = {
    boot = {
      # systemd in stage-1 initrd is cool but it doesn't work yet on at least kosame
      # TODO: Check if it works now, and bug report if it still doesn't
      # initrd.systemd.enable = true;
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
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
