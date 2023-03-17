{ pkgs, lib, nixosConfig ? null, ... }:
{
  imports = [
    ./fish.nix
    ./tmux.nix
  ];

  home.packages = [
    pkgs.direnv
  ];

  targets.genericLinux.enable = lib.mkIf (nixosConfig == null) true;
}
