{ config, pkgs, lib, ... }:
{
  config = {
    services.xserver.libinput = {
      # Enable touchpad/mouse
      enable = true;
      # Disable mouse accel
      mouse = { accelProfile = "flat"; };
    };

    services.fwupd.enable = true;
    hardware.openrazer.enable = true;
    hardware.steam-hardware.enable = true;
    hardware.enableRedistributableFirmware = true;
    hardware.wirelessRegulatoryDatabase = true;
    hardware.ledger.enable = true;
    # use with piper for gaming mouse configuration
    services.ratbagd.enable = true;
  };
}
