{ pkgs, flakeArgs, ... }:
{
  home.packages = [
    flakeArgs.erosanix.packages.${pkgs.system}.foobar2000
  ];
}
