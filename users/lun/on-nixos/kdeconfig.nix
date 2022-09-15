{ lib, pkgs, ... }:
let
  toValue = v:
    if builtins.isString v then
      v
    else if builtins.isBool v then
      lib.boolToString v
    else if builtins.isInt v then
      builtins.toString v
    else
      builtins.abort ("Unknown value type: " ++ builtins.toString v);
  configs = {
    kwinrc = {
      Compositing = {
        GLCore = true;
        OpenGLIsUnsafe = false;
        LatencyPolicy = "ExtremelyLow";
        MaxFPS = 165;
        RefreshRate = 165;
        Enabled = false;
      };
      TabBox = {
        LayoutName = "compact";
      };
    };
    kcminputrc = {
      Mouse = {
        XLbInptAccelProfileFlat = true;
      };
    };
    kdeglobals = {
      KDE = {
        SingleClick = false;
      };
    };
  };
  lines = lib.flatten (lib.mapAttrsToList
    (file:
      lib.mapAttrsToList
        (group:
          lib.mapAttrsToList
            (key: value:
              "$DRY_RUN_CMD ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file $confdir/'${file}' --group '${group}' --key '${key}' '${
                toValue value
              }'")
        ))
    configs);
in
{
  home.activation.kwriteconfig5 = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    _() {
      confdir="''${XDG_CONFIG_HOME:-$HOME/.config}"
      ${builtins.concatStringsSep "\n" lines}

      $DRY_RUN_CMD ${pkgs.libsForQt5.qt5.qttools.bin}/bin/qdbus org.kde.KWin /KWin reconfigure || echo "KWin reconfigure failed"
      for i in {0..10}; do
        $DRY_RUN_CMD ${pkgs.dbus}/bin/dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:$i int32:0 || echo "KGlobalSettings.notifyChange failed"
      done
    } && _
    unset -f _
  '';
}
