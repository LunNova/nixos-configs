{ config, ... }:
{
  config = {
    lun.persistence.dirs = [
      "/root" # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=962987 >:(
      "/home"
    ];
  };
}
