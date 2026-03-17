{ config, pkgs, lib, ... }:
let
  name = "outofdateinator";
  cfg = config.lun.${name};
  # test with systemctl --user start outofdateinator-force
  # ALL PTSes MUST KNOW
  beep = pkgs.resholve.writeScriptBin "${name}-beep"
    {
      inputs = with pkgs; [ sox ];
      interpreter = "${pkgs.bash}/bin/bash";
    } ''
    echo "outdated get beeped at"
    for t in /dev/pts/[0-9]*;do printf '\a'>"$t" 2>/dev/null;done
    play -qn synth .1 sine 3200 pad .15 repeat 2
  '';
  script = pkgs.resholve.writeScriptBin name
    {
      inputs = (with pkgs; [ coreutils findutils curl jq ]) ++ [ beep ];
      interpreter = "${pkgs.bash}/bin/bash";
      fake.external = [ "firefox" ];
    } ''
    c=''${XDG_CACHE_HOME:-~/.cache}/ff-ver
    [ -n "$(find "$c" -mmin -180 2>/dev/null)" ]||curl -sf https://product-details.mozilla.org/1.0/firefox_versions.json|jq -r .LATEST_FIREFOX_VERSION>"$c"
    v=$(<"$c")
    b=$(firefox --version 2>/dev/null);b=''${b##* }
    echo "ff latest=$v installed=$b"
    [ -z "$v" ]||[ -z "$b" ]||printf '%s\n' "$v" "$b"|sort -VC&&exit
    exec ${name}-beep
  '';
in
{
  options.lun.${name}.enable = lib.mkEnableOption name;
  config = lib.mkIf cfg.enable {
    systemd.user.services.${name} = {
      path = lib.mkForce [ ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe script}";
      };
    };
    systemd.user.services."${name}-force" = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe beep}";
      };
    };
    systemd.user.timers.${name} = {
      wantedBy = [ "default.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
