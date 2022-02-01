{ pkgs, ... }: {
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      noto-fonts
      # noto-fonts-cjk # Reenable after https://github.com/NixOS/nixpkgs/pull/156342 is merged
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
    ];
  };
}
