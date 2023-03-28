{ pkgs, ... }:
{
  config = {
    home.packages = [
      pkgs.pavucontrol
    ];
  };
}
