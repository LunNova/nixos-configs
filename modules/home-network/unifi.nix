{ lib, config, pkgs, ... }:
let cfg = config.lun.unifi; in
{
  options.lun.unifi.enable = lib.mkEnableOption "Enable unifi controller";

  config = {
    services.unifi = lib.mkIf cfg.enable {
      enable = true;
      unifiPackage = pkgs.unifi;
      openFirewall = true;
      jrePackage = pkgs.jre8_headless;
    };
  };
}
