{ pkgs }:
# TODO can this maybe suck less
# https://discourse.nixos.org/t/making-xdg-open-more-resilient/16777
pkgs.writeShellScriptBin "xdg-open" ''
  #!/bin/sh

  echo "xdg-open workaround: Launching $@"

  env -i RUST_BACKTRACE=1 USER="$USER" HOME="$HOME" \
      XDG_DATA_HOME=$XDG_DATA_HOME XDG_DATA_DIRS=$XDG_DATA_DIRS XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XAUTHORITY=$XAUTHORITY DISPLAY=$DISPLAY KDE_SESSION_VERSION=$KDE_SESSION_VERSION XDG_CURRENT_DESKTOP=X-Generic \
      bash -lc 'env | sort >> ~/dev/xdg-open-log && ${pkgs.lun.handlr}/bin/handlr open '"$@"
''
