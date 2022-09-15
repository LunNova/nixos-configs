{ config, pkgs, ... }:
{
  config = {
    nixpkgs.overlays = [
      (_self: super: {
        xdg-utils = super.xdg-utils.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            
            sed -i '2i if ${pkgs.lun.xdg-open-with-portal}/bin/xdg-open "$1"; then exit 0; fi;' $out/bin/xdg-open
          '';
        });
      })
    ];
  };
}
