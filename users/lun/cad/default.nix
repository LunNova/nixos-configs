{ config, lib, pkgs, pkgs-stable, self, ... }:
{
  home.packages = [
    pkgs.openscad
  ];
}
