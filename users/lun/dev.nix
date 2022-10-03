{ pkgs, ... }:
{
  home.packages = [
    pkgs.jetbrains.clion
    pkgs.jetbrains.idea-ultimate
    pkgs.jetbrains.pycharm-professional
  ];
}
