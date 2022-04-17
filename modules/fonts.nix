{ pkgs, ... }: {
  fonts = {
    enableDefaultFonts = true;

    # Use mkForce because we can't turn off the x fonts while x server is enabled
    fonts = with pkgs; lib.mkForce [
      # General fonts
      noto-fonts
      noto-fonts-cjk
      liberation_ttf
      carlito # Similar to MS Calibri
      ttf_bitstream_vera

      # Japanese
      ipafont
      kochi-substitute

      # Code/monospace and nsymbol fonts
      (nerdfonts.override { fonts = [ "Hack" ]; })
      fira-code
      fira-code-symbols
      mplus-outline-fonts.osdnRelease
      dina-font
      proggyfonts
      font-awesome_4
      font-awesome_5
      dejavu_fonts
      source-code-pro

      # Emoji
      twitter-color-emoji
      noto-fonts-emoji
      noto-fonts-extra
    ];
  };
}
