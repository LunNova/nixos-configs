#!/bin/sh
set -euo pipefail

nixos-rebuild build --flake .#
nix build .#homeManagerConfigurations.lun.activationPackage
