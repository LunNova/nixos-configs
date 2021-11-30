#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq
set -xeuo pipefail

nix flake show --json | jq '[leaf_paths as $path | select(getpath($path) == "derivation") | {"key": $path | join(".") | sub(".type";""), "value": getpath($path)}] | from_entries | keys|.[]' -cr | xargs -tI{} nix build .#{}
nixos-rebuild build --flake .#
