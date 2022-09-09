{ pkgs, ... }:
{
  config = {
    programs.adb.enable = true;
    users.users.lun.extraGroups = [ "adbusers" ];
  };
}
