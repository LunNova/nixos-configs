# https://github.com/ibraheemdev/modern-unix/
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    lsd
    delta
    duf
    fd
    ripgrep
    jq
    tldr
    gtop
    gping
    procs
    htop
    atop
    smartmontools
    linuxPackages_latest.perf
  ];
}
