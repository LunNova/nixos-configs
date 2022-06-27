{ pkgs, ... }:
{
  home.packages = with pkgs; [
    smplayer
    vlc
    mpv
  ];
}
