{ system, pkgs, flake-args }:
let
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
    patches = old.patches ++ [ ];
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts ];
  });
  xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
in
{
  input-remapper = pkgs.python3Packages.callPackage ./input-remapper { };
  powercord = pkgs.callPackage ./powercord {
    plugins = { };
    themes = { };
  };
  kwinft = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./kwinft { });
  xdg-open-with-portal = xdg-open-with-portal;
  lutris-unwrapped = lutris-unwrapped;
  lutris = pkgs.lutris.override {
    lutris-unwrapped = lutris-unwrapped;
    extraLibraries = pkgs: [ (pkgs.hiPrio xdg-open-with-portal) ];
  };
  spawn = pkgs.callPackage ./spawn { };
  swaysome = pkgs.callPackage ./swaysome { };
  sworkstyle = pkgs.callPackage ./sworkstyle { };
}
