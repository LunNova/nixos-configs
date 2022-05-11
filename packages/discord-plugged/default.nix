{ symlinkJoin
, discord-canary
, powercord-overlay
, powercord
, extraElectronArgs ? ""
, makeBinaryWrapper
}:
symlinkJoin {
  name = "discord-plugged";
  paths = [ discord-canary.out ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  postBuild = ''
    injectTarg="$out/opt/DiscordCanary/resources/app"
    if [ -d $out/opt/DiscordCanary/resources/app.asar.unpacked ]; then
      injectTarg="$out/opt/DiscordCanary/resources/app.asar.unpacked"
    fi
    mkdir $injectTarg || true
    cp -r --remove-destination ${powercord-overlay}/plugs/* $injectTarg/
    substituteInPlace $injectTarg/index.js --replace 'POWERCORD_SRC' '${powercord}'

    makeWrapper $(readlink "$out/opt/DiscordCanary/DiscordCanary") $out/opt/DiscordCanary/DiscordCanary --add-flags "${extraElectronArgs}"
  '';

  meta.mainProgram = if (discord-canary.meta ? mainProgram) then discord-canary.meta.mainProgram else null;
}
