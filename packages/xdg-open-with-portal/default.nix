{ pkgs }:
# TODO can this maybe suck less
# https://discourse.nixos.org/t/making-xdg-open-more-resilient/16777
pkgs.writeShellScriptBin "xdg-open" ''
  #!/bin/sh

  targetFile=$1

  # trying to avoid issues if whatever handles org.freedesktop.portal ends up calling this script again
  if ! ${pkgs.psmisc}/bin/pstree -s -p $$ | grep -q xdg-desktop-portal ; then
    >&2 echo "xdg-open workaround: using org.freedesktop.portal to open $targetFile"

    openFile=OpenFile
    # https://github.com/flatpak/xdg-desktop-portal/issues/683
    # if [ -d "$targetFile" ]; then
    #   openFile=OpenDirectory
    # fi

    if [ -e "$targetFile" ]; then
      exec 3< "$targetFile"
      gdbus call --session \
        --dest org.freedesktop.portal.Desktop \
        --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.portal.OpenURI.$openFile \
        --timeout 5 \
        "" "3" {}
    else
      if ! echo "$targetFile" | grep -q '://'; then
        targetFile="https://$targetFile"
      fi

      gdbus call --session \
        --dest org.freedesktop.portal.Desktop \
        --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.portal.OpenURI.OpenURI \
        --timeout 5 \
        "" "$targetFile" {}
    fi
  else
    >&2 echo "xdg-open workaround: using xdg-open to open $targetFile as seem to have been invoked recursively"
    env -i RUST_BACKTRACE=1 USER="$USER" HOME="$HOME" \
      $(systemctl --user show-environment | grep -v \$\' | xargs)
      ${pkgs.xdg-utils}/bin/xdg-open "$targetFile"
  fi
''
