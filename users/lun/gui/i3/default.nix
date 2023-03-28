{ config, lib, pkgs, ... }:
# https://github.com/berbiche/dotfiles/blob/df1cf43f9f7b267e7b4bf3a9e6cc8e4b4defb680/profiles/i3/home-manager/i3-config.nix#L4
#
# TODO: eww from https://github.com/FlafyDev/nixos-config/blob/fd7bbff67dfaf056a56d028a9e434722e400fa88/configs/eww/hm-custom-eww.nix
let
  mod = "Mod4";
  drun = "${pkgs.rofi}/bin/rofi -show run";
  menu = "${pkgs.rofi}/bin/rofi -show combi";
  screenshot = pkgs.writeShellScript "i3-screenshot" ''
    path="$HOME/sync/screenshots/$(hostname)-$(date "+%Y-%m-%d %T").png" && ${pkgs.maim}/bin/maim -s "$path" && ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png "$path"
  '';
  fonts = [
    "Liberation Mono"
    "Font Awesome 6 Free"
    "Font Awesome 6 Brands"
  ];
in
{
  xdg.configFile."i3wsr/config.toml".text = ''
    [icons]
    firefox = ""
    Emacs = ""
    kitty = ""
  '';
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      inherit fonts;

      modifier = mod;

      keybindings = config.wayland.windowManager.sway.config.keybindings // {
        "Print" = "exec ${screenshot}";
        "${mod}+x" = "exec sh -c '${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png'";
        "${mod}+q" = "exec sh -c '${pkgs.i3lock}/bin/i3lock -c ba9bff & sleep 2 && ${pkgs.xorg.xset}/bin/xset dpms force off'";
        "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${mod}+space" = "exec ${drun}";
        "${mod}+d" = "exec ${menu}";
        "${mod}+i" = "bar hidden_state toggle";
      };

      startup = [
        {
          command = "${pkgs.writeShellScript "i3-wallpaper" ''
            if [ "$XDG_CURRENT_DESKTOP" = "none+i3" ]; then
              ${pkgs.feh}/bin/feh --bg-scale ~/.background-image
            fi
          ''}";
          notification = false;
        }
        {
          command = "${pkgs.i3wsr}/bin/i3wsr --icons awesome -r -m";
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
          #font = "pango:DejaVu Sans Mono, FontAwesome 12";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${./i3status-rust.toml}";
        }
      ];
    };
  };
}
