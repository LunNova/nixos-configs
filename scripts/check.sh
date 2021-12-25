#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#jq -c bash
# shellcheck shell=bash
set -xeuo pipefail

nix flake check
nix flake show --json | jq 'del(.devShell) | [leaf_paths as $path | select(getpath($path) == "derivation") | {"key": $path | join(".") | sub(".type";""), "value": getpath($path)}] | from_entries | keys|.[]' -cr | xargs -tI{} nix build --no-link .#{}
nix eval ".#homeConfigurations" --apply 'f: builtins.concatStringsSep "\n" (builtins.attrNames f)' --raw | \
  xargs -tI{} nix build --no-link .#homeConfigurations.{}.activationPackage
if [ -v 1 ] && [ "$1" == "all" ]; then
    nix flake show --json | jq '.nixosConfigurations | keys[] as $k | select(.[$k].type=="nixos-configuration") | $k' -cr | xargs -tI{} nix build --no-link .#nixosConfigurations.{}.config.system.build.toplevel
elif [ -f /etc/NIXOS ]; then
    nix build --no-link ".#nixosConfigurations.$(hostname).config.system.build.toplevel"
fi
