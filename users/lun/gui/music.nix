{ pkgs, flake-args, ... }:
{
  home.packages = [
    flake-args.erosanix.packages.${pkgs.system}.foobar2000
  ];
}
