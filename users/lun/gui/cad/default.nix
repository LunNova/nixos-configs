{ pkgs, ... }:
{
  home.packages = [
    # FIXME: enable after next staging-next -> staging
    # https://github.com/NixOS/nixpkgs/issues/205363
    # pkgs.openscad
  ];
}
