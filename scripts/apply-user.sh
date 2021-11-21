#!/bin/sh
set -euo pipefail

pushd $(readlink -f "$(dirname $(readlink -f "$0"))/..")

nix build .#homeManagerConfigurations.lun.activationPackage
./result/activate

#home-manager switch -f lun-home.nix


