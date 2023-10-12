#!/usr/bin/env bash
set -xeuo pipefail

# This is a bodge.
# amayadori's boot SSD sometimes seems to drop recent writes when it hangs and reboots
function sync_pls() {
	sync
	sudo btrfs filesystem sync /nix/store/ || true
	sudo btrfs filesystem sync /nix/var/nix/ || true
	sync
}

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

echo "Activating ${1:-toplevel}"
$(which nom 2>/dev/null || which nix) build -j 4 -o tmp-system-build --keep-going ".#nixosConfigurations.$(hostname).config.system.build.toplevel"

profile="/nix/var/nix/profiles/system"
pathToConfig="$(readlink -f tmp-system-build)"
rm tmp-system-build

sync_pls
sleep 1

sudo nix-env -p "$profile" --set "$pathToConfig"

if [[ -v 1 ]]; then
	sudo "$pathToConfig/specialisation/$1/bin/switch-to-configuration" switch
else
	sudo "$pathToConfig/bin/switch-to-configuration" switch
fi

sync_pls

sudo "$pathToConfig/bin/switch-to-configuration" boot

# home-manager switch used to handle this?
# since swapping to home-manager.nixosModules.home-manager seem to need to do this to get changes to happen immediately
sudo systemctl restart home-manager-\* --all

sync_pls
