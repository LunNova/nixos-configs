{ pkgs, ... }:
{
  home.packages = [
    pkgs.nix-output-monitor
    pkgs.jetbrains.clion
    pkgs.jetbrains.idea-ultimate
    pkgs.jetbrains.pycharm-professional
  ];
}
