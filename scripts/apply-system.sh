#!/usr/bin/env bash
set -euo pipefail

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"
sudo nixos-rebuild switch --flake .#
