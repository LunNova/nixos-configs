{ pkgs, ... }:
{
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle manager for Wayland";
      Documentation = "man:swayidle(1)";
      PartOf = "graphical-session.target";
    };

    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          lock "swaylock -f" \
          timeout 600 "swaymsg 'output * dpms off'" \
          resume "swaymsg 'output * dpms on'" \
          timeout 660 "loginctl lock-session" \
          before-sleep "loginctl lock-session"
      '';
    };

    Install = { WantedBy = [ "sway-session.target" ]; };
  };
}
