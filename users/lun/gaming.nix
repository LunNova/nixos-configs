{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # osu-lazer not currently playing
    prismlauncher # Hi emstar (:
    lun.lutris
    # TODO: try bottles instead of lutris
  ];
}
