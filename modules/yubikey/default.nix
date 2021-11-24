{ config, lib, pkgs,  ... }:
let
  cfg = config.sconfig.yubikey;
in
{
  options.sconfig.yubikey = lib.mkEnableOption "Enable yubikey tools";

  config.services.udev.packages = with pkgs; lib.mkIf cfg [
    yubikey-personalization
  ];

  config.environment.systemPackages = with pkgs; lib.mkIf cfg [
    yubikey-personalization
    yubikey-manager
    yubikey-manager-qt
    yubikey-personalization-gui
  ];
}

