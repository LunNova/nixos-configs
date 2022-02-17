{ pkgs, ... }: {
  fonts = {
    enableDefaultFonts = false;

    # Use mkForce because we can't turn off the x fonts while x server is enabled
    fonts = with pkgs; lib.mkForce [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      noto-fonts-extra
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
      font-awesome_4
      font-awesome_5
      (nerdfonts.override { fonts = [ "Hack" ]; })

      # Defaults from https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/fonts/fonts.nix
      dejavu_fonts
      freefont_ttf
      gyre-fonts # TrueType substitutes for standard PostScript fonts
      liberation_ttf
      unifont
      noto-fonts-emoji
    ];

    # You also can't override the lucida font packages
    # not possible due to https://github.com/NixOS/nixpkgs/issues/41154
    # xorg = prev.xorg.overrideScope' (self: super:
    #   {
    #     fontbhlucidatypewriter100dpi = final.emptyDirectory;
    #     fontbhlucidatypewriter75dpi = final.emptyDirectory;
    #   }
    # );
  };
}
