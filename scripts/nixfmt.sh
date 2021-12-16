#!/usr/bin/env bash
set -xeuo pipefail

nix run nixpkgs#nixpkgs-fmt .
