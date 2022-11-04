#!/usr/bin/env -S nix --extra-experimental-features "nix-command flakes" shell nixpkgs#bubblewrap nixpkgs#slirp4netns -c bash
# shellcheck shell=bash

set -euo pipefail

echo launching bwrap

rm /tmp/wait-pid 2>/dev/null || true

echo "nameserver 1.1.1.1" >/tmp/resolv-conf

bwrap --unshare-net --bind /tmp /tmp --bind /dev /dev --bind /proc /proc --bind /nix /nix --bind /home /home --bind /run /run --bind /tmp/resolv-conf /etc/resolv.conf \
	bash -c "echo \$$ > /tmp/wait-pid; while [ -e /tmp/wait-pid ]; do sleep 0.1; done; echo launching inner; exec $(printf -- '"%s" ' "$@")" &

main_proc=$!

while [ ! -e /tmp/wait-pid ]; do
	sleep 0.1
done

sleep 2

pid=$(cat /tmp/wait-pid)

echo "launching slirp4netns in $pid"

slirp4netns --configure --mtu=1500 --disable-host-loopback "$pid" eno1 &
slirp_proc=$!

sleep 0.5

rm /tmp/wait-pid

wait

wait $main_proc
kill $slirp_proc
