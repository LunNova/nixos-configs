#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/NIXOS ]]; then
	echo "This script is only for nixos systems"
	exit 1
fi

profile="/nix/var/nix/profiles/system"
flakeref=".#nixosConfigurations.$(hostname).config.system.build.toplevel"

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

echo "Activating $flakeref (spec ${1:-toplevel}) as $profile"

nix="$(which nom 2>/dev/null || which nix)"
result="$("$nix" build -j 4 --no-link --print-out-paths --keep-going "$flakeref")"

if [ -f "$result/bin/switch-to-configuration" ]; then
	sudo scripts/apply-system-derivation.sh "$profile" "$result"
else
	exit 1
fi
