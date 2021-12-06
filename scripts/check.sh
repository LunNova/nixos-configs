#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#jq -c bash
set -xeuo pipefail

nix flake show --json | jq 'del(.devShell) | [leaf_paths as $path | select(getpath($path) == "derivation") | {"key": $path | join(".") | sub(".type";""), "value": getpath($path)}] | from_entries | keys|.[]' -cr | xargs -tI{} nix build .#{}
nixos-rebuild build --flake .#
