#!/usr/bin/env bash
set -euo pipefail

pushd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"
nix flake update

