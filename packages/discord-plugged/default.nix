{ symlinkJoin
, discord-canary
, powercord-overlay
, powercord
, extraElectronArgs ? ""
}:
symlinkJoin {
  name = "discord-plugged";
  paths = [ discord-canary.out ];

  postBuild = ''
    removelink() {
      [ -L "$1" ] && cp --remove-destination "$(readlink "$1")" "$1"
    }
    set -x
    injectTarg="$out/opt/DiscordCanary/resources/app"
    if [ -d $out/opt/DiscordCanary/resources/app.asar.unpacked ]; then
      injectTarg="$out/opt/DiscordCanary/resources/app.asar.unpacked"
    fi
    mkdir $injectTarg || true
    ls $injectTarg
    cp -r --remove-destination ${powercord-overlay}/plugs/* $injectTarg/
    ls $injectTarg
    substituteInPlace $injectTarg/index.js --replace 'POWERCORD_SRC' '${powercord}'
    substituteInPlace $injectTarg/package.json --replace 'index.js' "$injectTarg/index.js"

    cp -a --remove-destination $(readlink "$out/opt/DiscordCanary/.DiscordCanary-wrapped") "$out/opt/DiscordCanary/.DiscordCanary-wrapped" || true
    cp -a --remove-destination $(readlink "$out/opt/DiscordCanary/DiscordCanary") "$out/opt/DiscordCanary/DiscordCanary"
    substituteInPlace $out/opt/DiscordCanary/DiscordCanary \
      --replace '${discord-canary.out}' "$out" \
      --replace '"$@"' '${extraElectronArgs} "$@"'
  '';

  meta.mainProgram = if (discord-canary.meta ? mainProgram) then discord-canary.meta.mainProgram else null;
}
