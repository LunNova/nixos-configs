# https://github.com/ibraheemdev/modern-unix/
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    lsd
    delta
    dust
    duf
    fd
    ripgrep
    jq
    tldr
    gtop
    gping
    procs
  ];
}
