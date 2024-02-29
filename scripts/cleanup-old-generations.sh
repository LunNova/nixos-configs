#!/usr/bin/env bash
if [[ ! -f /etc/NIXOS ]]; then
	echo "This script is only for nixos systems"
	echo "If you're on a nixos system make sure you aren't inside an FHS environment shell"
	exit 1
fi
if [[ $(id -u) -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

set -xeuo pipefail

nix-collect-garbage --delete-older-than 3d
nix profile wipe-history --profile /home/lun/.local/state/nix/profiles/home-manager

/nix/var/nix/profiles/system/bin/switch-to-configuration boot

nix-store --gc
nix store gc --verbose --no-keep-derivations --no-keep-env-derivations
nix store optimise
sync

fstrim -av
