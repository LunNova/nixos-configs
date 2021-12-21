{ config, lib, pkgs, ... }:
let
  cfg = config.sconfig.yubikey;
in
{
  options.sconfig.yubikey = lib.mkEnableOption "Enable yubikey tools";

  config = lib.mkIf cfg {
    services.udev.packages = with pkgs; lib.mkIf cfg [
      yubikey-personalization
    ];

    environment.systemPackages = with pkgs; lib.mkIf cfg [
      yubikey-personalization
      yubikey-manager
      yubikey-manager-qt
      yubikey-personalization-gui
    ];

    security.pam.u2f = {
      enable = true;
      cue = true;
      authFile = "/etc/pam-u2f/pam-u2f.cfg";
    };

    lun.persistence.files = [ "/etc/pam-u2f/pam-u2f.cfg" ];
  };
}

