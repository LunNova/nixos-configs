#!/bin/sh
set -euo pipefail

pushd $(readlink -f "$(dirname $(readlink -f "$0"))/..")
sudo nixos-rebuild switch --flake .#
