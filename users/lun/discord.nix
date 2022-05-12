{ config, lib, pkgs, inputs, self, ... }:
{
  home.packages = [
    pkgs.lun.discord-plugged-lun
  ];
}
