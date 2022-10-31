{ lib, config, ... }:
{
  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  systemd.user.services.${config.services.syncthing.tray.package.pname} = {
    Install.WantedBy = lib.mkForce [ ];
  };
  systemd.user.timers.${config.services.syncthing.tray.package.pname} = {
    Timer = {
      OnActiveSec = "10s";
      AccuracySec = "1s";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
