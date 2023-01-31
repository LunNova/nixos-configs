{ pkgs, flakeArgs, ... }:
{
  home.packages = [
    pkgs.openscad

    flakeArgs.nixpkgs-cura-testing.legacyPackages.${pkgs.system}.cura
  ];
}
