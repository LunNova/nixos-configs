{ lib, pkgs, flakeArgs, ... }:
let
  extraElectronArgs = "--ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy --disable-smooth-scrolling";
  discordPathSuffix = "";
  extractCmd = pkgs.makeBinaryWrapper.extractCmd or (pkgs.writeShellScript "extract-binary-wrapper-cmd" ''
    strings -dw "$1" | sed -n '/^makeCWrapper/,/^$/ p'
  '');
in
{
  home.packages =
    if (pkgs.system == "x86_64-linux") then
      [
        ((pkgs.discord.override {
          withOpenASAR = true;
          withVencord = true;
        }).overrideAttrs (old: {
          postInstall = ''
            ${old.postInstall}
            if grep '\0' $out/opt/Discord${discordPathSuffix}/Discord${discordPathSuffix} && wrapperCmd=$(${extractCmd} $out/opt/Discord${discordPathSuffix}/Discord${discordPathSuffix}) && [[ $wrapperCmd ]]; then
              # Binary wrapper
              parseMakeCWrapperCall() {
                shift # makeCWrapper
                oldExe=$1; shift
                oldWrapperArgs=("$@")
              }
              eval "parseMakeCWrapperCall ''${wrapperCmd//"$out"/"$out"}"
              # Binary wrapper
              makeWrapper $oldExe $out/opt/Discord${discordPathSuffix}/Discord${discordPathSuffix} "''${oldWrapperArgs[@]}" --add-flags "${extraElectronArgs}"
            else
              # Normal wrapper
              substituteInPlace $out/opt/Discord${discordPathSuffix}/Discord${discordPathSuffix} \
              --replace '"$@"' '${extraElectronArgs} "$@"'
            fi
          '';
        }))
      ] else [ pkgs.armcord ];
}
