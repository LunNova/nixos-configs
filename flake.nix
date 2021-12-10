{
  description = "nixpkgs with unfree";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, ... }@args:
    let
      lib = args.nixpkgs.lib;
      systems = lib.systems.supported.hydra;
      forAllSystems = f: lib.genAttrs systems (system: f system);
    in
    (args.nixpkgs // {
      legacyPackages = forAllSystems (system: import args.nixpkgs { inherit system; config.allowUnfree = true; });
    });
}
