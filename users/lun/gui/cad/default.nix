{ pkgs, lib, flakeArgs, ... }:
{
  home.packages = [
    pkgs.openscad
  ] ++ lib.optionals (pkgs.system == "x86_64-linux") [
    flakeArgs.nixpkgs-cura-testing.legacyPackages.${pkgs.system}.cura
  ];
}
