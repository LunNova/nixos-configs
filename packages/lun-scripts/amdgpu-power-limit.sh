#!/bin/bash
set -euo pipefail

watts="$1"
target=$((watts * 1000000))

for card in /sys/class/drm/card[0-9]; do
	old_cap=$(cat "$card"/device/hwmon/hwmon*/power1_cap)
	echo -e "Card $card\t$old_cap\t->\t$target"
	echo "$target" | sudo tee "$card"/device/hwmon/hwmon*/power1_cap
done
