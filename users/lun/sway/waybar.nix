_:
let
  firefoxIcon = "";
in
{
  programs.waybar = {
    enable = true;
    style = builtins.readFile ./waybar.css;
    settings = [{
      position = "left";
      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "sway/window" ];
      modules-right = [ "cpu" "battery" "memory" "clock" "pulseaudio" "tray" "custom/power" ];
      modules.clock.format = "{:%H:%M}";

      battery = {
        format = "{capacity}%  {icon}";
        format-alt = "{time} {icon}";
        format-charging = "{capacity}%  ";
        format-icons = [ "" "" "" "" "" ];
        format-plugged = "{capacity}%  ";
        states = { critical = 15; warning = 30; };
      };
      "sway/window" = {
        rotate = 270;
        "format" = "{}";
        "max-length" = 50;
        "rewrite" = {
          "(.*) [-—] Mozilla Firefox" = "${firefoxIcon} $1";
          "nvim (.*) /.*" = " $1";
          #"imv (.*) /.*" = " $1";
          "(.*) [-—] Visual Studio Code" = " $1";
          "(.*) [-—] Discord" = "‭ﭮ $1";
          "(.*) [-—] vim" = " $1";
          "fish (.*)" = " $1";
        };
      };
      "custom/power" = {
        "format" = "";
        "on-click" = "swaynag -t warning -m 'Power Menu Options' -b 'Logout' 'swaymsg exit' -b 'Suspend' 'swaymsg exec systemctl suspend' -b 'shutdown' 'systemctl shutdown'";
      };
      "sway/workspaces" = {
        all-outputs = true;
        disable-scroll = true;
        format = "{name}: {icon}";
        persistent_workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
        format-icons = { "1" = ""; "2" = "${firefoxIcon}"; "3" = ""; "4" = ""; "5" = ""; default = ""; focused = ""; urgent = ""; };
      };
    }];
    systemd.enable = false;
  };
}
