# Copied from github:buckley310/nixos-config, MIT
{ config, lib, ... }:
let
  cfg = config.lun.libinput-patches;
in
{
  options.lun.libinput-patches =
    {
      double-scroll-speed = lib.mkEnableOption "Double mouse scroll speed in xf86libinput (X11 only)";
      accel-default-off = lib.mkEnableOption "Disable mouse acceleration by default in libinput";
    };

  config = lib.mkMerge [
    (lib.mkIf cfg.double-scroll-speed {
      nixpkgs.overlays = [
        (self: super: {
          xorg = super.xorg.overrideScope' (selfB: superB: {
            inherit (super.xorg) xlibsWrapper;
            xf86inputlibinput = superB.xf86inputlibinput.overrideAttrs (attr: {
              patches = [ ./libinput.patch ./no-accel.patch ];
            });
          });
        })
      ];
    })
    (lib.mkIf cfg.accel-default-off {
      nixpkgs.overlays = [
        (self: super: {
          runtime-patched.libinput = super.libinput.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./libinput-no-accel.patch ];
          });
        })
      ];
    })
    {
      environment.etc."libinput/local-overrides.quirks".text = ''
        [Never Debounce]
        MatchUdevType=mouse
        ModelBouncingKeys=1
      '';
    }
  ];
}
