_:
{
  config = {
    services.chrony = {
      enable = true;
      extraConfig = ''
        leapsecmode slew
      '';
      servers = [
        "0.pool.ntp.org"
        "1.pool.ntp.org"
        "2.pool.ntp.org"
        "3.pool.ntp.org"
      ];
    };
    services.timesyncd.enable = false;
    services.ntp.enable = false;
    lun.persistence.dirs = [ "/var/lib/chrony" ];
  };
}
