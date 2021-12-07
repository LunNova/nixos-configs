#!/usr/bin/env bash
set -xeuo pipefail

# nixpkgs/nixos-21.11
nix run nixpkgs/96b4157790fc96e70d6e6c115e3f34bba7be490f#nixpkgs-fmt .
