# Approach originally from https://github.com/tejing1/
{ pkgs, config, lib, flake-args, ... }:
let
  inherit (lib.strings) escapeNixIdentifier;
  inherit (flake-args.self.lib) mkFlake;
in
{
  config = {
    system.configurationRevision = lib.mkIf (flake-args.self ? rev) flake-args.self.rev; # set configurationRevision if available

    # Legacy compat for non-flake uses:
    # Update immediately by using paths instead of needing to get new NIX_PATH env
    nix.nixPath = [ "/etc/nix/path" ];
    environment.etc."nix/path/nixpkgs".source = flake-args.nixpkgs;

    #nixpkgs=input nixpkgs
    nix.registry.nixpkgs.flake = flake-args.nixpkgs;
    nix.registry.nixpkgs-stable.flake = flake-args.nixpkgs-stable;

    #nix.registry.nixos-config.flake = lun;
    #pkgs = pkgs provided to this system
    nix.registry.pkgs.flake =
      mkFlake pkgs { config = flake-args.self; }
        "{config,...}: {legacyPackages.${escapeNixIdentifier config.nixpkgs.system}=config.nixosConfigurations.${escapeNixIdentifier config.networking.hostName}.pkgs;}";
  };
}
