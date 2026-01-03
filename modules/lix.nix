{ pkgs, ... }:
{
  # nix.package = pkgs.lixPackageSets.git.lix;
  nix.package = pkgs.nixVersions.latest; # Using nix as of 2.30 due to significant perf improvements

  # HACK: sleep for 1s in pre-build-hook until load average is below some number
  # cpus=$(${pkgs.coreutils}/bin/nproc)
  # cpus=$((cpus / 2)) # assume hyperthreading
  # nix.settings.pre-build-hook = pkgs.writeScript "nix-pre-build-hook" ''#!/usr/bin/env bash
  #   set -euf

  #   cpus=20
  #   while true; do
  #     load=$(< /proc/loadavg)
  #     load_int=''${load%%.*}

  #     [ "$load_int" -gt "$cpus" ] || break
  #     sleep 1
  #   done
  # '';
}
