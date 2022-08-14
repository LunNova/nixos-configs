#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#jq -c bash
# shellcheck shell=bash
set -xeuo pipefail

nix flake check
if [ -v 1 ] && [ "$1" == "all" ]; then
	sys="$(nix eval --impure --expr builtins.currentSystem)"
	nix build -L --no-link --keep-going ".#slowChecks.$sys.all"
elif [ -f /etc/NIXOS ]; then
	nix build --no-link --keep-going ".#nixosConfigurations.$(hostname).config.system.build.toplevel"
fi
