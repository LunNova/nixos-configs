{ config, lib, pkgs, inputs, self, ... }:
{
  imports = [
    ./fish.nix
    ./tmux.nix
  ];

  home.packages = [
    pkgs.direnv
  ];
}
