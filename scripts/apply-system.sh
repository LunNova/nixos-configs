#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/NIXOS ]]; then
	echo "This script is only for nixos systems"
	exit 1
fi
if [[ $(id -u) -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

profile="/nix/var/nix/profiles/system"
flakeref=".#nixosConfigurations.$(hostname).config.system.build.toplevel"

# This is a bodge.
# amayadori's boot SSD sometimes seems to drop recent writes when it hangs and reboots
function sync_pls() {
	sync
	if command -v btrfs >/dev/null; then
		btrfs filesystem sync /nix/store/ || true
		btrfs filesystem sync "$profile" || true
	fi
}

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

echo "Activating $flakeref (spec ${1:-toplevel}) as $profile"
$(which nom 2>/dev/null || which nix) build  -j 4 --no-link --profile "$profile" --keep-going "$flakeref"

sync_pls
sleep 1

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
