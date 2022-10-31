#!/usr/bin/env bash
set -xeuo pipefail
IFS=$'\n'

for dir in $(nix eval --raw ".#nixosConfigurations.$(hostname).config.lun.persistence.dirs_for_shell_script"); do
	mkdir -p "$dir" "/persist$dir"
	mount -o bind "/persist$dir" "$dir" || true
done
