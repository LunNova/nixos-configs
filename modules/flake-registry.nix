# Approach originally from https://github.com/tejing1/
{ pkgs, ... }:
{
  config = {
    #system.configurationRevision = lib.mkIf (flakeArgs.self ? rev) flakeArgs.self.rev; # set configurationRevision if available

    # Legacy compat for non-flake uses:
    # Update immediately by using paths instead of needing to get new NIX_PATH env
    nix.nixPath = [ "/etc/nix/path" ];
    environment.etc."nix/path/nixpkgs".source = pkgs;

    #nixpkgs=input nixpkgs
    nix.registry.nixpkgs.flake = pkgs;

    #nix.registry.nixos-config.flake = lun;
    #pkgs = pkgs provided to this system
    # nix.registry.pkgs.flake = flakeArgs.nixpkgs;
    # FIXME: Figure out better way to get a `pkgs` that is this flake's overlayed pkgs available as `pkgs` flake
    # mkFlake pkgs { config = flakeArgs.self; }
    #   "{config,...}: {legacyPackages.${escapeNixIdentifier pkgs.system}=config.pkgs.${escapeNixIdentifier pkgs.system};}";
  };
}
