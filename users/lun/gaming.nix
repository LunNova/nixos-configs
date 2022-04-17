{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # osu-lazer not currently playing
    polymc # Hi emstar (:
    lun.lutris
    # TODO: try bottles instead of lutris
  ];
}
