{ pkgs, config, ... }:

{
  config = rec {
    home.pointerCursor = {
      enable = true;
      name = "BreezeX-RosePine-Linux";
      size = 32;
      package = pkgs.rose-pine-cursor;
      # hyprcursor.enable = true;
      # hyprcursor.size = 32;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      HYPRCURSOR_THEME = "rose-pine-hyprcursor";
      HYPRCURSOR_SIZE = config.home.pointerCursor.size;
      XCURSOR_SIZE = config.home.pointerCursor.size;
    };

    gtk = {
      iconTheme = {
        name = "rose-pine";
        package = pkgs.rose-pine-icon-theme;
      };

      theme = {
        name = "rose-pine";
        package = pkgs.rose-pine-gtk-theme;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 0;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 0;
      };
    };

    services.xsettingsd = {
      settings = {
        "Net/IconThemeName" = "${gtk.iconTheme.name}";
        "Net/ThemeName" = "${gtk.theme.name}";
      };
    };

    xdg =
      let
        themeDir = "${gtk.theme.package}/share/themes/${gtk.theme.name}";
      in
      {
        dataFile."icons/rose-pine-hyprcursor".source = "${pkgs.rose-pine-hyprcursor}/share/icons/rose-pine-hyprcursor";
        configFile."gtk-4.0/gtk.css".source = "${themeDir}/gtk-4.0/gtk.css";
      };
  };
}
