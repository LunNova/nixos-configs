{ config, lib, pkgs, flakeArgs, ... }:
{
  options.lun.profiles.gaming = (lib.mkEnableOption "Enable common profile") // { default = true; };
  config = lib.mkIf config.lun.profiles.gaming {
    programs.steam.enable = true;
    # programs.steam.package =
    #   let
    #     # nixpkgs-ancient = 18.03 tag
    #     ancientPkgs = import "${flakeArgs.nixpkgs-ancient}" { system = pkgs.system; };
    #     bodge = pkgs: pkgs.runCommandLocal "badvlclib" { } ''
    #     # mkdir -p $out/lib
    #     # ln -sf ${pkgs.vlc}/lib/*.so* $out/lib/
    #     # ln -sf ${pkgs.vlc}/lib/*.so $out/lib/
    #     # ln -sf ${pkgs.vlc}/lib/vlc/* $out/lib/
    #     # ln -sf ${pkgs.vlc}/lib/libvlccore.so.9 $out/lib/libvlccore.so.8
    #     # for ffl in ${pkgs.ffmpeg_4}/lib/*; do
    #     #   fn="$(basename "$ffl")"
    #     #   fn="''${fn/.58/".57"}"
    #     #   ln -sf $ffl $out/lib/$fn
    #     # done
    #     mkdir -p $out/bin
    #     ln -s ${pkgs.yt-dlp}/bin/yt-dlp $out/bin/youtube-dl
    #     ln -s ${pkgs.yt-dlp}/bin/yt-dlp $out/bin/yt-dl
    #     '';
    #     extra = pkgs: [
    #       pkgs.ffmpeg_4
    #       pkgs.ffmpeg_5
    #       pkgs.xorg.libX11
    #       pkgs.xorg.libXrandr
    #       pkgs.yt-dlp
    #       pkgs.xorg.libXau
    #       pkgs.xorg.libXdmcp
    #       pkgs.lz4
    #       pkgs.libidn
    #       pkgs.libidn2
    #       pkgs.mpg123
    #       pkgs.libmad
    #       #pkgs.vlc
    #       #pkgs.libxcb
    #     ] ++ lib.optionals pkgs.hostPlatform.is64bit [
    #       #ancientPkgs.vlc
    #       #ancientPkgs.ffmpeg_3
    #       pkgs.vlc
    #       pkgs.libvlc
    #       (bodge pkgs)
    #     ];
    #   in
    #   pkgs.steam.override {
    #     extraLibraries = pkgs: (if pkgs.hostPlatform.is64bit
    #     then [ config.hardware.opengl.package ]
    #     else [ config.hardware.opengl.package32 ]) ++ extra pkgs;
    #     extraPkgs = extra;
    #   };
    services.input-remapper.enable = true;
  };
}
