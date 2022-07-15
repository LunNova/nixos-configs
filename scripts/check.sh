#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#jq -c bash
# shellcheck shell=bash
set -xeuo pipefail

nix flake check
if [ -v 1 ] && [ "$1" == "all" ]; then
	sys="$(nix eval --impure --expr builtins.currentSystem)"
	nix build ".#slowChecks.$sys.all" -L --no-link
elif [ -f /etc/NIXOS ]; then
	nix build --no-link ".#nixosConfigurations.$(hostname).config.system.build.toplevel"
fi
