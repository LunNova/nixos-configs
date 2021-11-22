{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
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
          modules = [ ./system.nix ];
        };
      };
    };
}
