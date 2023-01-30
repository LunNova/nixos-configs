{ pkgs, ... }:
{
  home.packages = [
    pkgs.yt-dlp # required for neos video player
    pkgs.lighthouse-steamvr # lighthouse on/off
  ];
}
