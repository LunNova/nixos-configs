{ config, lib, ... }:
{
  options.lun.profiles.server = lib.mkEnableOption "Enable server profile";
  config = lib.mkIf config.lun.profiles.server {
    sound.enable = false;
    hardware.opengl = lib.mkForce {
      enable = false;
    };
  };
}
