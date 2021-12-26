{ writeShellScriptBin
, glib
, bash
}:
# TODO can this maybe suck less
# https://discourse.nixos.org/t/making-xdg-open-more-resilient/16777
writeShellScriptBin "xdg-open" ''
  #!${bash}/bin/bash

  # exec > >(tee -i ~/dev/xdg-open-portal-log.txt)
  # exec 2>&1

  targetFile=$1
  beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

  >&2 echo "xdg-open workaround: using org.freedesktop.portal to open $targetFile"

  openFile=OpenFile
  # https://github.com/flatpak/xdg-desktop-portal/issues/683
  # if [ -d "$targetFile" ]; then
  #   openFile=OpenDirectory
  # fi

  if beginswith . "$targetFile" || beginswith / "$targetFile" || [ -e "$targetFile" ]; then
    exec 3< "$targetFile"
    ${glib}/bin/gdbus call --session \
      --dest org.freedesktop.portal.Desktop \
      --object-path /org/freedesktop/portal/desktop \
      --method org.freedesktop.portal.OpenURI.$openFile \
      --timeout 5 \
      "" "3" {}
  else
    if ! echo "$targetFile" | grep -q '://'; then
      targetFile="https://$targetFile"
    fi

    ${glib}/bin/gdbus call --session \
      --dest org.freedesktop.portal.Desktop \
      --object-path /org/freedesktop/portal/desktop \
      --method org.freedesktop.portal.OpenURI.OpenURI \
      --timeout 5 \
      "" "$targetFile" {}
  fi
''
