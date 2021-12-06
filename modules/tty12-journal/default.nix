# http://log.or.cz/?p=327
{ config, lib, pkgs, ... }:
let
  cfg = config.sconfig.tty12-journal;
in
{
  options.sconfig.tty12-journal = {
    enable = lib.mkEnableOption "Enable tty12 journal logs";
  };

  config = lib.mkIf cfg.enable {
    systemd.targets.getty.wants = [ "journal@tty12.service" ];
    systemd.services."journal@tty12" = {
      enable = true;
      description = "Journal tail on %i";
      after = [
        "systemd-user-sessions.service"
        "systemd-journald.service"
      ];
      unitConfig = {
        ConditionPathExists = "/dev/tty0";
      };
      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash -c \"exec ${pkgs.systemd}/bin/journalctl -af > /dev/%I 2> /dev/%I\"";
        Type = "idle";
        Restart = "always";
        RestartSec = "1";
        UtmpIdentifier = "%I";
        TTYPath = "/dev/%I";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "no";
        KillMode = "process";
        IgnoreSIGPIPE = "no";
        Environment = "LANG= LANGUAGE= LC_CTYPE= LC_NUMERIC= LC_TIME= LC_COLLATE= LC_MONETARY= LC_MESSAGES= LC_PAPER= LC_NAME= LC_ADDRESS= LC_TELEPHONE= LC_MEASUREMENT= LC_IDENTIFICATION=";
      };
      # ...
    };
  };
}
