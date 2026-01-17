{ pkgs, config, ... }:
let
  # For reasons I'm not fully understanding, GTK apps on wayland
  # need ibus enabled and running with an engine set up
  # or they will fail to handle unicode compose key sequences (ones using a Uxxxx number)
  # but still handle ones with a text name
  # %L is equivalent to include "${pkgs.xorg.libX11}/share/X11/locale/en_US.UTF-8/Compose"
  composeText = ''
    include "%L"
    <Multi_key> <period> <backslash>           : "λ"   U03BB  # GREEK SMALL LETTER LAMBDA
  '';
in
{
  home.keyboard = {
    layout = "us";
    variant = "altgr-intl";
    options = [ "compose:rwin" ];
  };
  home.sessionVariables = {
    XCOMPOSEFILE = "${config.home.homeDirectory}/.XCompose";
    XKB_DEFAULT_LAYOUT = config.home.keyboard.layout;
    XKB_DEFAULT_VARIANT = config.home.keyboard.variant;
    XKB_DEFAULT_OPTIONS = pkgs.lib.concatStringsSep "," config.home.keyboard.options;
  };
  home.file.".XCompose".text = composeText;
  xdg.configFile."XCompose".text = composeText;
  xdg.configFile."gtk-3.0/Compose".text = composeText;
}
