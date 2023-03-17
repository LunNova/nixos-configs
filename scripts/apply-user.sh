#!/usr/bin/env bash
set -euo pipefail

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

nix build .#homeConfigurations."$(nix eval --impure --raw --expr 'builtins.currentSystem')".lun.activationPackage
./result/activate

#home-manager switch -f lun-home.nix
