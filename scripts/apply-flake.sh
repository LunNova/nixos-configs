#!/usr/bin/env bash
set -xeuo pipefail

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

if [[ -v 1 ]]; then
    echo "Activating spec $1"
    nix build -o tmp-system-build ".#nixosConfigurations.$(hostname).config.system.build.toplevel"

    profile="/nix/var/nix/profiles/system"
    pathToConfig="$(readlink -f tmp-system-build)"
    rm tmp-system-build

    sudo nix-env -p "$profile" --set "$pathToConfig"
    sudo "$pathToConfig/specialisation/$1/bin/switch-to-configuration" switch
    sudo "$pathToConfig/bin/switch-to-configuration" boot
else
    echo "No spec set, will activate default"
    sudo nixos-rebuild switch --flake ".#"
fi

# home-manager switch used to handle this?
# since swapping to home-manager.nixosModules.home-manager seem to need to do this to get changes to happen immediately
sudo systemctl restart home-manager-\* --all
