{ config, lib, pkgs, ... }:
let
  cfg = config.sconfig.input-remapper;
  mapper-pkg = [ pkgs.input-remapper ];
in
{
  options.sconfig.input-remapper = lib.mkEnableOption "Enable input-remapper";

  # FIXME: udev rule hangs, see package
  # config.services.udev.packages = mapper-pkg;
  config.services.dbus.packages = mapper-pkg;
  config.systemd.packages = mapper-pkg;
  config.environment.systemPackages = mapper-pkg;
  config.systemd.services.input-remapper.wantedBy = [ "graphical.target" ];
}
