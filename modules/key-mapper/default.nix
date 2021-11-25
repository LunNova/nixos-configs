{ config, lib, pkgs,  ... }:
let
  cfg = config.sconfig.key-mapper;
  mapper-pkg = with pkgs; lib.mkIf cfg [
    my.key-mapper
  ];
in
{
  options.sconfig.key-mapper = lib.mkEnableOption "Enable key-mapper";

  config.services.udev.packages = mapper-pkg;
  config.services.dbus.packages = mapper-pkg;
  config.systemd.packages = mapper-pkg;
  config.environment.systemPackages = mapper-pkg;
}
