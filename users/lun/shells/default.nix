{ pkgs, ... }:
{
  imports = [
    ./fish.nix
    ./tmux.nix
  ];

  home.packages = [
    pkgs.direnv
  ];
}
