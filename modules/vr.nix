{ pkgs, config, lib, flakeArgs, ... }:
{
  config = lib.mkIf (with config.lun.profiles; graphical && gaming) {
    services.udev.packages = [ flakeArgs.openxr-nix-flake.packages.${pkgs.stdenv.hostPlatform.system}.xr-hardware ];
  };
}
