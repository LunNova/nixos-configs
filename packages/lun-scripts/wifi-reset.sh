#!/usr/bin/env bash
set -xeu
# Find wifi remove file
remove="$(echo /sys/class/net/wlp*/device/remove)"
# Remove the wireless adapter, log if can't, keep going anyway in case rescanning works
echo 1 >"$remove" || echo >&2 "$0 can't write to $remove. Wifi card not found or not running as root"
# Wait a bit
sleep 4
# Rescan PCI bus
echo 1 >/sys/bus/pci/rescan
# Restart networking services (in my case various things with NetworkManager in the name)
systemctl restart '*etwork*.service'
systemctl status '*etwork*.service'
