{ config, pkgs, lib, ... }:
{
  config = lib.mkMerge [
    {
      services.fwupd.enable = true;
      hardware.wirelessRegulatoryDatabase = true;
      hardware.enableRedistributableFirmware = true;
      # use with piper for gaming mouse configuration
      # services.ratbagd.enable = true;

      # no USB wakeups
      # see: https://github.com/NixOS/nixpkgs/issues/109048
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="disabled"
      '';
    }

    (lib.mkIf config.lun.profiles.graphical {
      services.xserver.libinput = {
        # Enable touchpad/mouse
        enable = true;
        # Disable mouse accel
        mouse = { accelProfile = "flat"; };
      };

      # udev rule for zsa oryx
      hardware.keyboard.zsa.enable = true;
      # steam controller and index headset, only works on x86_64 as of 202309
      hardware.steam-hardware.enable = pkgs.system == "x86_64-linux";
      hardware.ledger.enable = true;

      services.udev.packages = [ pkgs.lun.vial ];
      environment.systemPackages = [ pkgs.lun.vial ];

      # FIXME: xone doesn't work with wireless, seems unmaintained?
      # find something better or patch it
      # hardware.xone.enable = true;
    })
  ];
}
