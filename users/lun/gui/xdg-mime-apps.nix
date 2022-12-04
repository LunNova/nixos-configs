_:

let
  browser = [
    "firefox.desktop" # assume firefox provides this
  ];
  associations = {
    "inode/directory" = [ "org.kde.dolphin.desktop" ];
    "text/html" = browser;
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    "x-scheme-handler/ftp" = browser;
    "x-scheme-handler/chrome" = browser;
    "x-scheme-handler/about" = browser;
    "x-scheme-handler/unknown" = browser;
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/xhtml+xml" = browser;
    "application/x-extension-xhtml" = browser;
    "application/x-extension-xht" = browser;
    # obsidian stop deleting my mimeapps.list please
    "x-scheme-handler/obsidian" = [ "obsidian.desktop" ];
  };
in
{
  xdg.configFile."mimeapps.list".force = true; # too many apps replace this link when opened to add their own definitions
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.associations.added = associations;
  xdg.mimeApps.defaultApplications = associations;
}
