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

    home-manager.sharedModules = [
      {
        xdg.configFile."kcminputrc".text = ''
          [Mouse]
          XLbInptAccelProfileFlat=true
        '';
      }
    ];
  };
}
