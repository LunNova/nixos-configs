{ config, lib, pkgs, inputs, self, ... }:
{
  home.packages = [
    (pkgs.discord-plugged.override {
      # TODO make it launch with 
      # discordcanary --ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy
      discord-canary = pkgs.discord-canary.override { };
      powercord = pkgs.lun.powercord;
      plugins = pkgs.powercord-plugins;
      themes = pkgs.powercord-themes;
    })
  ];
}
