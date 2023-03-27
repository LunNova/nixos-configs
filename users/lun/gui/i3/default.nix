{ config, lib, pkgs, ... }:
# https://github.com/berbiche/dotfiles/blob/df1cf43f9f7b267e7b4bf3a9e6cc8e4b4defb680/profiles/i3/home-manager/i3-config.nix#L4
let
  mod = "Mod4";
  drun = "${pkgs.rofi}/bin/rofi -show run";
  menu = "${pkgs.rofi}/bin/rofi -show combi";
in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = mod;

      fonts = [ "DejaVu Sans Mono, FontAwesome 6" ];

      # FIXME: override wofi stuff in sway, won't work
      keybindings = config.wayland.windowManager.sway.config.keybindings // {
        "${mod}+x" = "exec sh -c '${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png'";
        "${mod}+q" = "exec sh -c '${pkgs.i3lock}/bin/i3lock -c ba9bff & sleep 5 && xset dpms force of'";
        "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${mod}+space" = "exec ${drun}";
        "${mod}+d" = "exec ${menu}";
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
      ];

      bars = [
        {
          position = "bottom";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${./i3status-rust.toml}";
        }
      ];
    };
  };
}
