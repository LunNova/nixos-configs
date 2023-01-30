{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # osu-lazer not currently playing
    prismlauncher # Hi emstar (:
    lun.lutris
    pkgs.lun.wine
    # TODO: try bottles instead of lutris
  ];
}
