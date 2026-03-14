{ pkgs, config, lib, ... }:
# Using a much more minimal set of system fonts now because
# battle.net seems to break if there are lots of fonts
let lotsOfFonts = false;
in
{
  fonts = lib.mkIf config.lun.profiles.graphical {
    enableDefaultPackages = false;

    packages = lib.mkForce (with pkgs; [
      dejavu_fonts
      freefont_ttf
      gyre-fonts # TrueType substitutes for standard PostScript fonts
      liberation_ttf
      unifont
      corefonts # Times New Roman, …
      vista-fonts # Calibri, Cambria, Candara, Consolas, Constantia, Corbel
      font-awesome

      symbola # only font with alchemical symbol block?
      last-resort
      meslo-lg #-nf

      font-awesome_4
      font-awesome_5
      nerd-fonts.caskaydia-cove # symbol font for bars

      ipafont
      kochi-substitute
      noto-fonts-cjk-sans

      # Apple UI fonts, override XML below sets these as monospace default
      lun.sf-pro
      lun.sf-mono
    ] ++ lib.optionals lotsOfFonts [
      # General fonts
      liberation_ttf
      ttf_bitstream_vera

      # Japanese
      ipafont
      kochi-substitute

      # Code/monospace and nsymbol fonts
      mplus-outline-fonts.osdnRelease
      fira-code
      fira-code-symbols
      dina-font
      proggyfonts
      dejavu_fonts
      source-code-pro
      iosevka-bin

      # Emoji
      noto-fonts
      noto-fonts-emoji
      noto-fonts-extra
    ]);

    # Lucida -> iosevka as no free Lucida font available and it's used widely
    fontconfig.localConf = lib.optionalString false ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        ${lib.optionalString lotsOfFonts ''
        <match target="pattern">
          <test name="family" qual="any"><string>Lucida</string></test>
          <edit name="family" mode="assign">
            <string>iosevka</string>
          </edit>
        </match>
        ''}
        <!-- Map Menlo to Meslo LG S -->
        <match target="pattern">
          <test name="family">
            <string>Menlo</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Meslo LG S</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family" qual="any">
            <string>ui-monospace</string>
          </test>
          <edit binding="strong" mode="prepend" name="family">
            <string>SF Mono</string>
          </edit>
        </match>
        <match target="pattern">
          <test name="family" qual="any">
            <string>monospace</string>
          </test>
          <edit binding="strong" mode="prepend" name="family">
            <string>SF Mono</string>
          </edit>
        </match>

         <match target="font">
          <!-- none = grayscale antialiasing. have a mix of OLED and LCD with different subpixel layouts. -->
          <edit mode="assign" name="rgba"><const>none</const></edit>
        </match>
        <match target="font">
          <edit mode="assign" name="hinting">
          <bool>true</bool>
          </edit>
        </match>
        <match target="font">
          <edit mode="assign" name="hintstyle">
          <const>hintfull</const>
          </edit>
        </match>
        <match target="font">
          <edit mode="assign" name="antialias">
          <bool>true</bool>
          </edit>
        </match>
        <edit name="autohint" mode="assign">
            <bool>true</bool>
        </edit>
        <edit name="lcdfilter" mode="assign">
            <const>lcdnone</const>
        </edit>
      </fontconfig>
    '';
  };
}
