#!/usr/bin/env -S nix --extra-experimental-features "nix-command flakes" shell nixpkgs#bubblewrap -c bash
# shellcheck shell=bash
set -xeuo pipefail

app=$1
shift

EMPTY="$(mktemp -d)"
TMPHOME="$HOME/.local/boxxy-$app"

mkdir -p "$TMPHOME"

bwrap --ro-bind /bin /bin --ro-bind /run /run \
	--ro-bind /etc /etc --ro-bind /nix /nix \
	--dev /dev --bind /proc /proc \
	--bind "$EMPTY" /dev/dri \
	--bind "$TMPHOME" "$HOME" \
	--bind "$HOME/.Xauthority" "$HOME/.Xauthority" \
	"$@"
