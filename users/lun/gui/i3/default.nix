{ config, lib, pkgs, ... }:

let
  mod = "Mod4";
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
      };

      bars = [
        {
          position = "bottom";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${./i3status-rust.toml}";
        }
      ];
    };
  };
}
