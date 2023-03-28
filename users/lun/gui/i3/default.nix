{ config, lib, pkgs, ... }:
# https://github.com/berbiche/dotfiles/blob/df1cf43f9f7b267e7b4bf3a9e6cc8e4b4defb680/profiles/i3/home-manager/i3-config.nix#L4
#
# TODO: eww from https://github.com/FlafyDev/nixos-config/blob/fd7bbff67dfaf056a56d028a9e434722e400fa88/configs/eww/hm-custom-eww.nix
let
  mod = "Mod4";
  drun = "${lib.getExe pkgs.rofi} -show run";
  menu = "${lib.getExe pkgs.rofi} -show combi";
  i3-screenshot = pkgs.writeShellScriptBin "i3-screenshot" ''
    path="$HOME/sync/screenshots/$(hostname)-$(date "+%Y-%m-%d %T").png" && ${lib.getExe pkgs.maim} -s "$path" && ${lib.getExe pkgs.xclip} -selection clipboard -t image/png "$path"
  '';
  fonts = [
    "Liberation Mono"
    "Font Awesome 6 Free"
    "Font Awesome 6 Brands"
  ];
  i3-wp = pkgs.writeShellScriptBin "i3-wallpaper" ''
    if [ "$XDG_CURRENT_DESKTOP" = "none+i3" ]; then
      ${lib.getExe pkgs.feh} --bg-scale ~/.background-image
    fi
  '';
in
{
  xdg.configFile."i3wsr/config.toml".text = ''
    [icons]
    firefox = ""
    Emacs = ""
    kitty = ""
  '';
  home.packages = [
    pkgs.i3status-rust
    pkgs.i3wsr
    pkgs.feh
    i3-wp
    i3-screenshot
  ];
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      inherit fonts;

      modifier = mod;

      keybindings = config.wayland.windowManager.sway.config.keybindings // {
        "Print" = "exec ${lib.getExe i3-screenshot}";
        "${mod}+x" = "exec sh -c '${lib.getExe pkgs.maim} -s | ${lib.getExe pkgs.xclip} -selection clipboard -t image/png'";
        "${mod}+q" = "exec sh -c '${lib.getExe pkgs.i3lock} -c ba9bff & sleep 2 && ${lib.getExe pkgs.xorg.xset} dpms force off'";
        "${mod}+Return" = "exec ${lib.getExe pkgs.kitty}";
        "${mod}+space" = "exec ${drun}";
        "${mod}+d" = "exec ${menu}";
        "${mod}+i" = "bar hidden_state toggle";
      };

      startup = [
        {
          command = "${lib.getExe i3-wp}";
          notification = false;
        }
        {
          command = "${lib.getExe pkgs.i3wsr} --icons awesome -r -m";
          notification = false;
        }
      ];

      bars = [
        {
          position = "top";
          #mode = "hide";
          fonts = {
            names = fonts;
            size = 10.0;
          };
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${./i3status-rust.toml}";
        }
      ];
    };
  };
}
