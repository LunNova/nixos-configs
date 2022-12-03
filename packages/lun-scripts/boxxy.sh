#!/usr/bin/env -S nix --extra-experimental-features "nix-command flakes" shell nixpkgs#bubblewrap -c bash
# shellcheck shell=bash
set -xeuo pipefail

app=$1
shift

TMPHOME="$HOME/.local/boxxy-$app"

mkdir -p "$TMPHOME"

bwrap --ro-bind /bin /bin --ro-bind /run /run --ro-bind /etc /etc --ro-bind /nix /nix --bind /dev /dev --bind /proc /proc --bind "$TMPHOME" "$HOME" "$@"
