#!/bin/bash

activeBusId=$(printf '%x\n' "$(MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=1 vulkaninfo | grep pciBus | expand | tr -s ' ' | cut -d ' ' -f 4)")
for card in /sys/class/drm/card[0-9]; do
	target=$(readlink -m "$card")
	if echo "$target" | grep -q ":$activeBusId:00"; then
		if [ "z${1:-}" != "zquiet" ]; then
			echo Active GPU is "$activeBusId" which looks like "$target" >&2
		fi
		echo "$target"
	fi
done
