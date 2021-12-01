#!/usr/bin/env bash
set -xeuo pipefail

cd $(readlink -f "$(dirname $(readlink -f "$0"))/..")

if [[ -v 1 ]]; then
    echo "Activating spec $1"
    nixos-rebuild build --flake ".#" && sudo "result/specialisation/$1/bin/switch-to-configuration" switch
    sudo nixos-rebuild boot --flake ".#"
else
    echo "No spec set, will activate default"
    sudo nixos-rebuild switch --flake ".#"
fi

# home-manager switch used to handle this?
# since swapping to home-manager.nixosModules.home-manager seem to need to do this to get changes to happen immediately
sudo systemctl restart home-manager-lun
