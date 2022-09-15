{ lib, ... }:
{
  services.blueman-applet.enable = true;
  systemd.user.services.blueman-applet = {
    Install.WantedBy = lib.mkForce [ ];
  };
  systemd.user.timers.blueman-applet = {
    Timer = {
      OnActiveSec = "10s";
      AccuracySec = "1s";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
