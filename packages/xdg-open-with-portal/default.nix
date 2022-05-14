{ writeShellScriptBin
, glib
}:
# TODO can this maybe suck less
# https://discourse.nixos.org/t/making-xdg-open-more-resilient/16777
writeShellScriptBin "xdg-open" ''
  # uncomment to get logs somewhere and tail -f it.
  # exec > >(tee -i ~/dev/xdg-open-portal-log.txt)
  # exec 2>&1

  set -xeuo pipefail

  targetFile=$1

  # Some programs run xdg-open with no stderr available so || true is needed
  >&2 echo "xdg-open workaround: using org.freedesktop.portal to open $targetFile" || true

  if [ -e "$targetFile" ]; then
    exec 9999< "$targetFile"
    ${glib}/bin/gdbus call --session \
      --dest org.freedesktop.portal.Desktop \
      --object-path /org/freedesktop/portal/desktop \
      --method org.freedesktop.portal.OpenURI.OpenFile \
      --timeout 5 \
      "" "9999" {}
      exec 9999>&- || true
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
