{ config, lib, pkgs, inputs, self, ... }:
{
  home.packages = [
    (pkgs.discord-plugged.override {
      powercord = pkgs.lun.powercord;
      plugins = pkgs.powercord-plugins;
      themes = pkgs.powercord-themes;
    })
  ];
}
