{ pkgs, lib, lun-profiles, ... }:
{
  home.packages = with pkgs; [
    # osu-lazer not currently playing
    prismlauncher # Hi emstar (:
  ] ++ lib.optionals (lun-profiles.wineGaming or false) [
    lun.lutris
    pkgs.lun.wine
    # TODO: try bottles instead of lutris
  ];
}
