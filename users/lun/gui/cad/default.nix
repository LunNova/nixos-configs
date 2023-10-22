{ pkgs, lib, flakeArgs, ... }:
{
  home.packages = [
    pkgs.openscad
  ];
}
