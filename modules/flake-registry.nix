# Approach originally from https://github.com/tejing1/
{ pkgs, config, lib, flake-args, lun, ... }:
let
  inherit (lib.strings) escapeNixIdentifier;
  inherit (lun.lib) mkFlake;
in
{
  config = {
    system.configurationRevision = lib.mkIf (lun ? rev) lun.rev; # set configurationRevision if available

    # Legacy compat for non-flake uses:
    # Update immediately by using paths instead of needing to get new NIX_PATH env
    nix.nixPath = [ "/etc/nix/path" ];
    environment.etc."nix/path/nixpkgs".source = flake-args.nixpkgs;

    #nixpkgs=input nixpkgs
    nix.registry.nixpkgs.flake = flake-args.nixpkgs;

    nix.registry.nixos-config.flake = lun;
    #pkgs = pkgs provided to this system
    nix.registry.pkgs.flake =
      mkFlake pkgs { config = lun; }
        "{config,...}: {legacyPackages.${escapeNixIdentifier config.nixpkgs.system}=config.nixosConfigurations.${escapeNixIdentifier config.networking.hostName}.pkgs;}";
  };
}
