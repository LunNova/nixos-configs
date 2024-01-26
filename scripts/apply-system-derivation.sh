#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

profile="$1"; shift
result="$1"; shift

if ! [ -f "$result/bin/switch-to-configuration" ]; then
	>&2 echo "Invalid system derivation at $result"
	exit 1
fi

# This is a bodge.
# amayadori's boot SSD sometimes seems to drop recent writes when it hangs and reboots
function sync_pls() {
	sync
	if command -v btrfs >/dev/null; then
		btrfs filesystem sync /nix/store/ || true
		btrfs filesystem sync "$profile" || true
	fi
}

sync_pls
sleep 1

nix-env --profile "$profile" --set "$result"

sync_pls

if [[ -v 1 ]]; then
	"$profile/specialisation/$1/bin/switch-to-configuration" switch
else
	"$profile/bin/switch-to-configuration" switch
fi

sync_pls

"$profile/bin/switch-to-configuration" boot

# home-manager switch used to handle this?
# since swapping to home-manager.nixosModules.home-manager seem to need to do this to get changes to happen immediately
systemctl restart home-manager-\* --all
