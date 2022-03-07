{
  config = {
    virtualisation.docker.enable = true;
    lun.persistence.dirs = [ "/var/lib/docker" ];
  };
}
