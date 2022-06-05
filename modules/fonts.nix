{ pkgs, ... }: {
  fonts = {
    enableDefaultFonts = true;

    fonts = with pkgs; [
      # General fonts
      noto-fonts
      noto-fonts-cjk
      liberation_ttf
      carlito # Similar to MS Calibri
      ttf_bitstream_vera
      vistafonts # Calibri, Cambria, Candara, Consolas, Constantia, Corbel

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
      iosevka-bin

      # Emoji
      twitter-color-emoji
      noto-fonts-emoji
      noto-fonts-extra
    ];

    # Lucida -> iosevka as no free Lucida font available and it's used widely
    fontconfig.localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="family" qual="any"><string>Lucida</string></test>
          <edit name="family" mode="assign">
            <string>iosevka</string>
          </edit>
        </match>
      </fontconfig>
    '';
  };
}
