{ config, lib, ... }:
{
  options.lun.profiles.gaming = lib.mkEnableOption "Enable gaming profile";
  options.lun.profiles.wineGaming = lib.mkEnableOption "Enable wine gaming profile";
  config = lib.mkIf config.lun.profiles.gaming {
    programs.steam.enable = true;
    services.input-remapper.enable = true;
  };
}
