{ pkgs, config, lib, ... }:
{
  options.lun.tablet.enable = lib.mkEnableOption "drawing tablet support";

  config = lib.mkIf config.lun.tablet.enable {
    services.xserver.wacom.enable = true;
    environment.systemPackages = [
      pkgs.wacomtablet # KDE settings panel for wacom tablets
    ];
  };
}
