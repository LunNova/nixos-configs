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
    hardware.keyboard.zsa.enable = true;
    hardware.steam-hardware.enable = pkgs.system == "x86_64-linux";
    hardware.enableRedistributableFirmware = true;
    hardware.wirelessRegulatoryDatabase = true;
    hardware.ledger.enable = true;
    # use with piper for gaming mouse configuration
    # services.ratbagd.enable = true;

    # no USB wakeups
    # see: https://github.com/NixOS/nixpkgs/issues/109048
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="disabled"
    '';

    services.udev.packages = lib.optionals (pkgs.system == "x86_64-linux") [ pkgs.vial ];
    environment.systemPackages = lib.optionals (pkgs.system == "x86_64-linux") [ pkgs.vial ];

    # FIXME: xone doesn't work with wireless, seems unmaintained?
    # find something better or patch it
    # hardware.xone.enable = true;
  };
}
