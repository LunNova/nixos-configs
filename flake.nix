{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
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
            ./modules/scroll-boost
            ./modules/yubikey
            ./modules/key-mapper
            ./modules/amd-nvidia-laptop
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = import ./users self;
            }
          ];
        };
      };
    };
}
