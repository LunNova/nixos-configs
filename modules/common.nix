{ config, pkgs, lib, ... }:
{
  config = {
    my.home-manager.enabled-users = [ "lun" ];

    # LANGUAGE / I18N
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    };

    # CONSOLE
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };
    # Persist console when getty starts
    systemd.services."getty@".serviceConfig.TTYVTDisallocate = "no";

    # NIX
    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nixFlakes;
      daemonCPUSchedPolicy = "idle";
      extraOptions = "experimental-features = nix-command flakes";
      autoOptimiseStore = true;
    };

    # NETWORKING
    networking = {
      networkmanager.enable = true;
      networkmanager.wifi.backend = "iwd";
      # TODO: diagnose why we need this on home network
      resolvconf.dnsExtensionMechanism = false;
    };
    services.avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
      publish.addresses = true;
    };

    # SSH
    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      startWhenNeeded = true;
    };

    # BOOT
    boot = {
      initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-amd" "kvm-intel" ];
      extraModulePackages = [ ];
    };

    # HARDENING
    security.sudo.execWheelOnly = true;

    # CHECKS
    assertions = [
      {
        assertion = config.hardware.cpu.amd.updateMicrocode || config.hardware.cpu.intel.updateMicrocode;
        message = "updateMicrocode should be set for intel or amd";
      }
      {
        assertion = config.networking.hostId != null;
        message = "Set the networking.hostId option. Use `head -c4 /dev/random | od -A none -t x4` to generate.";
      }
    ];
  };
}
