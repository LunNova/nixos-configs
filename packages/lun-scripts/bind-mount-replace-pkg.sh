#!/usr/bin/env bash

set -xeuo pipefail

orig=$(nix build "$1" --no-link --print-out-paths)
replacement=$(nix build "$2" --no-link --print-out-paths)

echo "Replacing $orig with $replacement"
read -r -p "Press enter to continue"

sudo umount "$orig" || true
sudo mount -o bind -o ro "$orig" "$replacement"
