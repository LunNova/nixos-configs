#!/bin/sh
set -xeuo pipefail

sudo nix-collect-garbage --delete-older-than 3d
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot
