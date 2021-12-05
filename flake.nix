{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6752dcd0a143eb4a3340d3bc055f49ea03f649d3"; # usually nixos-unstable, reverted to before https://github.com/NixOS/nixpkgs/pull/144094#issuecomment-984623393 temporarily
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, pre-commit-hooks, ... }:
    let
      system = "x86_64-linux";
      mkPkgs = pkgs: extraOverlays:
        import pkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = extraOverlays;
        };
      pkgs = mkPkgs nixpkgs [ self.overlay ];
      lib = nixpkgs.lib;
      readModules = path: builtins.map (x: path + "/${x}") (builtins.attrNames (builtins.readDir path));
    in
    {
      packages."${system}" = {
        key-mapper = pkgs.callPackage packages/key-mapper { };
      };

      overlay = final: prev: {
        my = self.packages."${system}";
      };

      nixosConfigurations = {
        lun-laptop-1-nixos = lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.pkgs = pkgs; }
            home-manager.nixosModules.home-manager
            ./system.nix
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = import ./users self;
            }
          ] ++ (readModules ./modules);
        };
      };

      checks."${system}" = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
          };
        };
      };
      devShell."${system}" = nixpkgs.legacyPackages.${system}.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };
    };
}
