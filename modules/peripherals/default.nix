{ config, pkgs, ... }:
{
  config = {
    services.xserver.libinput = {
      # Enable touchpad/mouse
      enable = true;
      # Disable mouse accel
      mouse = { accelProfile = "flat"; };
    };

    services.fwupd.enable = true;
    hardware.steam-hardware.enable = true;
    hardware.enableRedistributableFirmware = true;
    hardware.wirelessRegulatoryDatabase = true;
    hardware.ledger.enable = true;
    # use with piper for gaming mouse configuration
    services.ratbagd.enable = true;

    # no USB wakeups
    # see: https://github.com/NixOS/nixpkgs/issues/109048
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="disabled"
    '';

    services.udev.packages = [ pkgs.vial ];
    environment.systemPackages = [ pkgs.vial ];

    hardware.xone.enable = true;
  };
}
