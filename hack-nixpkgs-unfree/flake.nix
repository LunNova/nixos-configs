{
  description = "nixpkgs with unfree";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/%REV%";
  };

  outputs = { self, ... }@args:
    let
      lib = args.nixpkgs.lib;
      systems = lib.systems.supported.hydra;
    in
    (args.nixpkgs // {
      legacyPackages = (lib.genAttrs systems) (system: import args.nixpkgs { inherit system; config.allowUnfree = true; });
    });
}
