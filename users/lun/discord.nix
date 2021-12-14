{ config, lib, pkgs, inputs, self, ... }:
{
  home.packages = [
    (pkgs.discord-plugged.override {
      plugins = pkgs.powercord-plugins;
      themes = pkgs.powercord-themes;
    })
  ];
}
