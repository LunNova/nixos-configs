#!/usr/bin/env bash
set -xeuo pipefail
IFS="$(printf "\n")"

for dir in $(nix eval --raw ".#nixosConfigurations.$(hostname).config.lun.persistence.dirs_for_shell_script"); do
	mkdir "/mnt$dir"
	mkdir "/mnt/persist$dir"
	mount -o bind "/mnt/persist$dir" "/mnt$dir"
done
