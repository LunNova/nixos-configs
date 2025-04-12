{ writeShellApplication
, coreutils
, systemd
, util-linux
, lib
}:
# Spawn a process inside systemd user slice
# Uses ExitType=cgroup to handle apps like vscode that are shortlived and spawn another process
# and apps that are long lived and don't spawn a new process without needing to guess
# or specify an exec mode
(writeShellApplication {
  name = "spawn";

  runtimeInputs = [ coreutils systemd util-linux ];

  text = ''
    [ "$#" -ge 1 ] || exit 1
    read -ra cmd <<<"$*"
    program="''${cmd[0]}"
    name="$(basename "$program")"
    uuid="$(uuidgen)"
    exec systemd-run --property=ExitType=cgroup --slice-inherit --slice="sl-$name-$uuid" --user --unit "run-$name-$uuid" "''${cmd[@]}"
  '';
}) // { meta.platforms = lib.platforms.linux; }
