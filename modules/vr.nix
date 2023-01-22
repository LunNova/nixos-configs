{ pkgs, flakeArgs, ... }:
{
  services.udev.packages = [ flakeArgs.openxr-nix-flake.packages.${pkgs.system}.xr-hardware ];
}
