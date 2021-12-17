# Copied from github:buckley310/nixos-config, MIT
{ config, lib, ... }:
let
  cfg = config.sconfig.scroll-boost;
in
{
  options.sconfig.scroll-boost = lib.mkEnableOption "Patch xf86-libinput scroll speed";

  config = lib.mkIf cfg {
    nixpkgs.overlays = [
      (self: super: {
        xorg = super.xorg.overrideScope' (selfB: superB: {
          inherit (super.xorg) xlibsWrapper;
          xf86inputlibinput = superB.xf86inputlibinput.overrideAttrs (attr: {
            patches = [ ./libinput.patch ./no-accel.patch ];
          });
        });
        libinput = super.libinput.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./libinput-no-accel.patch ];
        });
      })
    ];
    etc."libinput/local-overrides.quirks".text = ''
      [Never Debounce]
      MatchUdevType=mouse
      ModelBouncingKeys=1
    '';
  };
}
