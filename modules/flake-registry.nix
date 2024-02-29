# Approach originally from https://github.com/tejing1/
{ pkgs, config, lib, flakeArgs, ... }:
let
  inherit (lib.strings) escapeNixIdentifier;
  inherit (flakeArgs.self.lib) mkFlake;
in
{
  config = {
    system.configurationRevision = lib.mkIf (flakeArgs.self ? rev) flakeArgs.self.rev; # set configurationRevision if available

    # Legacy compat for non-flake uses:
    # Update immediately by using paths instead of needing to get new NIX_PATH env
    nix.nixPath = [ "/etc/nix/path" ];
    environment.etc."nix/path/nixpkgs".source = flakeArgs.nixpkgs;

    #nixpkgs=input nixpkgs
    nix.registry.nixpkgs.flake = flakeArgs.nixpkgs;
    nix.registry.nixpkgs-stable.flake = flakeArgs.nixpkgs-stable;

    #nix.registry.nixos-config.flake = lun;
    #pkgs = pkgs provided to this system
    nix.registry.pkgs.flake =
      mkFlake pkgs { config = flakeArgs.self; }
        "{config,...}: {legacyPackages.${escapeNixIdentifier pkgs.system}=config.pkgs.${escapeNixIdentifier pkgs.system};}";
  };
}
