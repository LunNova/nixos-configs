{ lib, pkgs, flakeArgs, ... }:
{
  home.packages = lib.optionals (pkgs.system == "x86_64-linux") [
    (flakeArgs.replugged-nix-flake.lib.makeDiscordPlugged {
      inherit pkgs;
      withOpenAsar = true;
      themes = pkgs.powercord-themes;
      plugins = pkgs.powercord-plugins;
      extraElectronArgs = "--ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy --disable-smooth-scrolling";
    })
  ];
}
