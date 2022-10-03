#!/bin/bash
set -euo pipefail

watts="${1:-100}"
profile="${2:-2}"
target=$((watts * 1000000))

for card in /sys/class/drm/card[0-9]; do
	old_cap=$(cat "$card"/device/hwmon/hwmon*/power1_cap)
	echo -e "Card $card \t $old_cap \t -> \t $target"
	echo "$target" | sudo tee "$card"/device/hwmon/hwmon*/power1_cap >/dev/null
	echo manual | sudo tee "$card"/device/power_dpm_force_performance_level >/dev/null
	echo "$profile" | sudo tee "$card"/device/pp_power_profile_mode >/dev/null
done

sleep 1

echo "pp_power_profile_mode: active mode has *"
cat /sys/class/drm/card0/device/pp_power_profile_mode
echo "mclks ""$(cat /sys/class/drm/card*/device/pp_dpm_mclk)"
echo "fclks ""$(cat /sys/class/drm/card*/device/pp_dpm_fclk)"
