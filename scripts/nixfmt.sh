#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash nixpkgs-fmt
set -xeuo pipefail

nixpkgs-fmt .
