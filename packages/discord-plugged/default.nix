{ symlinkJoin
, discord-canary
, powercord-overlay
, powercord
, extraElectronArgs ? ""
, makeBinaryWrapper
, writeShellScript
}:
let extractCmd = makeBinaryWrapper.extractCmd or (writeShellScript "extract-binary-wrapper-cmd" ''
  strings -dw "$1" | sed -n '/^makeCWrapper/,/^$/ p'
''); in
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

    cp -a --remove-destination $(readlink "$out/opt/DiscordCanary/.DiscordCanary-wrapped") "$out/opt/DiscordCanary/.DiscordCanary-wrapped" || true
    cp -a --remove-destination $(readlink "$out/opt/DiscordCanary/DiscordCanary") "$out/opt/DiscordCanary/DiscordCanary"

    if grep '\0' $out/opt/DiscordCanary/DiscordCanary && wrapperCmd=$(${extractCmd} $out/opt/DiscordCanary/DiscordCanary) && [[ $wrapperCmd ]]; then
      # Binary wrapper
      parseMakeCWrapperCall() {
        shift # makeCWrapper
        oldExe=$1; shift
        oldWrapperArgs=("$@")
      }
      eval "parseMakeCWrapperCall ''${wrapperCmd//"${discord-canary.out}"/"$out"}"
      # Binary wrapper
      makeWrapper $oldExe $out/opt/DiscordCanary/DiscordCanary "''${oldWrapperArgs[@]}" --add-flags "${extraElectronArgs}"
    else
      # Normal wrapper
      substituteInPlace $out/opt/DiscordCanary/DiscordCanary \
      --replace '${discord-canary.out}' "$out" \
      --replace '"$@"' '${extraElectronArgs} "$@"'
    fi

    rm $out/bin/discordcanary $out/bin/DiscordCanary || true
    ln -s $out/opt/DiscordCanary/DiscordCanary $out/bin/discordcanary
    ln -s $out/opt/DiscordCanary/DiscordCanary $out/bin/DiscordCanary
  '';

  meta.mainProgram = if (discord-canary.meta ? mainProgram) then discord-canary.meta.mainProgram else null;
}
