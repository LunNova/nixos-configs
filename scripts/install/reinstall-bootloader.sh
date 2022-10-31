#!/usr/bin/env -S nix --extra-experimental-features "nix-command flakes" shell nixpkgs#parted -c bash
# shellcheck shell=bash
set -euo pipefail

sudo NIXOS_INSTALL_BOOTLOADER=1 /run/current-system/bin/switch-to-configuration boot
sudo nix-shell -p efibootmgr refind --run "refind-install --root /"
