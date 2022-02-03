{ config, lib, pkgs, inputs, self, ... }:
{
  home.packages = [
    (pkgs.lun.discord-plugged.override {
      extraElectronArgs = "--ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy --disable-smooth-scrolling";
      powercord = pkgs.lun.powercord.override {
        plugins = pkgs.powercord-plugins;
        themes = pkgs.powercord-themes;
      };
    })
  ];
}
