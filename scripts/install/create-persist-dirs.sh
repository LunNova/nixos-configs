#!/usr/bin/env bash
set -xeuo pipefail
IFS="$(printf "\n")"

for dir in $(nix eval --raw ".#nixosConfigurations.$(hostname).config.lun.persistence.dirs_for_shell_script"); do
	mkdir "$dir"
	mkdir "/persist$dir"
	mount -o bind "/persist$dir" "$dir"
done
