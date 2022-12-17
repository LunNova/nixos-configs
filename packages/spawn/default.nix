{ writeShellApplication
, coreutils
, systemd
, util-linux
, lib
}:
# Spawn a process inside systemd user scope
(writeShellApplication {
  name = "spawn";

  runtimeInputs = [ coreutils systemd util-linux ];

  # TODO -p ReadOnlyPaths=/ -p ReadWritePaths / bubblewrap?
  text = ''
    [ "$#" -ge 1 ] || exit 1
    read -ra cmd <<<"$*"
    program="''${cmd[0]}"
    name="$(basename "$program")"
    uuid="$(uuidgen)"
    exec systemd-run --user --scope --unit "run-$name-$uuid" "''${cmd[@]}"
  '';
}) // { meta.platforms = lib.platforms.linux; }
