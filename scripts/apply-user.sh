#!/usr/bin/env bash
set -euo pipefail

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

nix build .#homeManagerConfigurations.lun.activationPackage
./result/activate

#home-manager switch -f lun-home.nix


