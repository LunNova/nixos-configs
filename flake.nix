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
          overlays = extraOverlays; #++ (lib.attrValues self.overlays);
        };
      pkgs = mkPkgs nixpkgs [ self.overlay ];
      lib = nixpkgs.lib;
    in
    {
      # = mapModules ./packages (p: pkgs.callPackage p { });
      packages."${system}".key-mapper = pkgs.callPackage packages/key-mapper { };

      overlay = final: prev: {
        my = self.packages."${system}";
      };

      homeManagerConfigurations = {
        lun = home-manager.lib.homeManagerConfiguration {
          inherit system pkgs;
          username = "lun";
          homeDirectory = "/home/lun";
          stateVersion = "21.05";
          configuration = {
            imports = [ ./lun-home.nix ];
          };
        };
      };
      nixosConfigurations = {
        lun-laptop-1-nixos = lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./system.nix
            ./modules/scroll-boost
            ./modules/yubikey
            ./modules/key-mapper
          ];
        };
      };
    };
}
