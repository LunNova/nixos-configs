# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  services.xserver.videoDrivers = [ "nvidia" "amd" ];

  nixpkgs.config.allowUnfree = true;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };

  swapDevices = [
    {
      device = "/.swapfile";
    }
  ];

  # high-resolution display
  # hardware.video.hidpi.enable = lib.mkDefault true;

  systemd.network.links."10-en-wlan-0" = {
    matchConfig.PermanentMACAddress = "e0:d4:64:8f:f4:03";
    linkConfig.Name = "en-wlan-0";
  };

  systemd.network.links."10-en-usb-0" = {
    matchConfig.PermanentMACAddress = "8c:ae:4c:dd:20:d8";
    linkConfig.Name = "en-usb-0";
  };
}
