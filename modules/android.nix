{ lib, config, ... }:
{
  config = lib.mkIf config.lun.profiles.androidDev {
    programs.adb.enable = true;
    users.users.lun.extraGroups = [ "adbusers" ];
  };
}
