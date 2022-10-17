{ lib, pkgs, ... }:
{
  config = {
    systemd.user.services.conky = {
      Unit = {
        Description = "Conky - unixy rainmeter alternative";
        PartOf = "graphical-session.target";
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c 'export PATH=${lib.makeBinPath [ pkgs.lm_sensors ]}''${PATH:+:}$PATH;export ACTIVE_GPU="$(${pkgs.lun.lun-scripts.active-gpu-path}/bin/active-gpu-path)";exec ${pkgs.conky}/bin/conky'
        '';
      };
    };
    systemd.user.timers.conky = {
      Timer = {
        OnActiveSec = "10s";
        AccuracySec = "1s";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
