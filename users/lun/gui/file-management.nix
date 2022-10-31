{ pkgs, ... }:
{
  config = {
    home.packages = [
      pkgs.qdirstat
      pkgs.k4dirstat
      pkgs.dolphin
    ];
  };
}
