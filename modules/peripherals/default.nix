{ config, pkgs, lib, ... }:
{
  config = {
    services.xserver.libinput = {
      # Enable touchpad/mouse
      enable = true;
      # Disable mouse accel
      mouse = { accelProfile = "flat"; };
    };

    hardware.openrazer.enable = true;
  };
}
