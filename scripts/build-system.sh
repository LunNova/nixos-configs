#!/usr/bin/env bash
set -xeuo pipefail

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

echo "Building ${1:-toplevel}"
$(which nom 2>/dev/null || which nix) build -j 4 --no-link --keep-going ".#nixosConfigurations.$(hostname).config.system.build.toplevel"
