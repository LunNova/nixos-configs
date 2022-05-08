# https://github.com/MatthewCroughan/nixcfg/blob/d577d164eadc777b91db423e59b4ae8b26853fc6/users/default.nix
{ config, lib, pkgs, pkgs-stable, ... }:
let
  cfg = config.my.home-manager;

  # TODO: are these sensible
  adminGroups = [
    "wheel" # Enable ‘sudo’ for the user.
    "plugdev" # openrazer requires this
    "openrazer"
    "docker"
    "video"
    "audio"

    # printing
    "scanner"
    "lp"
  ];
in
{
  options.my.home-manager.enabled-users = with lib; mkOption {
    type = with types; listOf string;
    description = "List of users to include home manager configs for";
    default = [ ];
  };


  config = lib.mkMerge [
    {
      home-manager = {
        extraSpecialArgs = { inherit pkgs-stable; };
      };
    }
    (lib.mkIf (builtins.elem "lun" cfg.enabled-users) {
      home-manager.users = {
        lun = ./lun;
      };

      users.users.lun = {
        isNormalUser = true;
        shell = pkgs.fish;
        # Change after install
        initialPassword = "nix-placeholder";
        # TODO: are these sensible
        extraGroups = adminGroups;
      };
    })
    (lib.mkIf (builtins.elem "mmk" cfg.enabled-users) {
      home-manager.users = {
        mmk = ./mmk;
      };

      users.users.mmk = {
        isNormalUser = true;
        shell = pkgs.fish;
        # Change after install
        initialPassword = "nix-placeholder";
        extraGroups = adminGroups;
      };
    })
  ];
}
