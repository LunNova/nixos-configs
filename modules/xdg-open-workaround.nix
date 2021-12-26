{ config, pkgs, lib, ... }:
{
  config = {
    environment.systemPackages = [ (pkgs.hiPrio pkgs.lun.xdg-open-with-portal) ];
  };
}
