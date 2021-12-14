{ config, lib, pkgs, inputs, self, ... }:
{
  imports = [
    ./fish.nix
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
}
