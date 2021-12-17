{ config, lib, pkgs, inputs, self, ... }:
{
  imports = [
    ./fish.nix
  ];

  home.packages = [
    pkgs.direnv
  ];
}
