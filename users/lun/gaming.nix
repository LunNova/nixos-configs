{ pkgs, ... }:
{
  home.packages = with pkgs; [
    osu-lazer
    polymc # Hi emstar (:
    lun.lutris
    # TODO: try bottles instead of lutris
  ];
}
