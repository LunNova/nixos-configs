{ system, pkgs }:
let
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    #wine = pkgs.wineWowPackages.staging;
    wine = pkgs.emptyDirectory;
  }).overrideAttrs (old: {
    patches = old.patches ++ [ ];
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts ];
  });
  xdg-open-handlr = pkgs.callPackage ./xdg-open-handlr { };
in
{
  key-mapper = pkgs.callPackage ./key-mapper { };
  powercord = pkgs.callPackage ./powercord {
    plugins = { };
    themes = { };
  };
  handlr = pkgs.callPackage ./handlr { };
  xdg-open-handlr = xdg-open-handlr;
  lutris-unwrapped = lutris-unwrapped;
  lutris = pkgs.lutris.override {
    lutris-unwrapped = lutris-unwrapped;
    extraLibraries = pkgs: [ (pkgs.hiPrio xdg-open-handlr) ];
  };
}
