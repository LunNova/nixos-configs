#!/usr/bin/env bash
if [[ ! -f /etc/NIXOS ]]; then
	echo "This script is only for nixos systems"
	exit 1
fi
if [[ $(id -u) -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

set -xeuo pipefail

nix-collect-garbage --delete-older-than 3d
/nix/var/nix/profiles/system/bin/switch-to-configuration boot

nix-store --optimise

fstrim -av
