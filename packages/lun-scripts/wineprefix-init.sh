#!/usr/bin/env -S nix --extra-experimental-features "nix-command flakes" shell pkgs#winetricks pkgs#nix-gaming.wine-ge -c bash
# shellcheck shell=bash

#WINEARCH=win64 WINEPREFIX="$(realpath "$1")" winetricks -q mf vcrun2019 vcrun2012 vcrun2008 corefonts

#WINEARCH=win64 WINEPREFIX="$(realpath "$1")" winetricks -q
WINEARCH=win64 WINEPREFIX="$(realpath "$1")" wine winecfg -v win10

WINEARCH=win64 WINEPREFIX="$(realpath "$1")" wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentBuild /t REG_SZ /d 19045 /f
WINEARCH=win64 WINEPREFIX="$(realpath "$1")" wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentBuildNumber /t REG_SZ /d 19045 /f
WINEARCH=win64 WINEPREFIX="$(realpath "$1")" wine reg add 'HKCU\SOFTWARE\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f
WINEARCH=win64 WINEPREFIX="$(realpath "$1")" wine reg add "HKLM\\HARDWARE\DESCRIPTION\System\MultifunctionAdapter\0\DiskController\0\DiskPeripheral" /v 0 /t REG_SZ /d 7de88519-9e14-43dc-8264-ef5fe931722a /f

# FIXME: wine doesn't support this hardware ID reg key
# \Registry\Machine\HARDWARE\DESCRIPTION\System\MultifunctionAdapter\0\DiskController\0\DiskPeripheral\0
