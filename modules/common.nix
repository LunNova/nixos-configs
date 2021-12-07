{ config, pkgs, lib, ... }:
{
  config = {
    my.home-manager.enabled-users = [ "lun" ];
    sconfig.scroll-boost = true; # modules/scroll-boost
    sconfig.yubikey = true; # modules/yubikey
    sconfig.key-mapper = true; # modules/key-mapper
    sconfig.tty12-journal.enable = true;

    # LANGUAGE / I18N
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    };
    time.timeZone = "America/Los_Angeles";
    time.hardwareClockInLocalTime = true;

    # CONSOLE
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };
    # Persist console when getty starts
    systemd.services."getty@".serviceConfig.TTYVTDisallocate = "no";

    # LOGGING
    services.journald.extraConfig = ''
      SystemMaxUse=500M
      MaxFileSec=1day
      MaxRetentionSec=1month
    '';

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
      tmpOnTmpfs = true;
    };

    # HARDWARE
    hardware = {
      enableRedistributableFirmware = true;
    };

    # HARDENING
    nix.allowedUsers = [ "@users" ];
    security = {
      sudo.execWheelOnly = true;
    };
    # https://github.com/NixOS/nixpkgs/blob/d6fe32c6b9059a054ca0cda9a2bb99753d1134df/nixos/modules/profiles/hardened.nix#L95
    boot.kernel.sysctl = with lib; {
      # Enable strict reverse path filtering (that is, do not attempt to route
      # packets that "obviously" do not belong to the iface's network; dropped
      # packets are logged as martians).
      "net.ipv4.conf.all.log_martians" = mkDefault true;
      "net.ipv4.conf.all.rp_filter" = mkDefault "1";
      "net.ipv4.conf.default.log_martians" = mkDefault true;
      "net.ipv4.conf.default.rp_filter" = mkDefault "1";

      # Ignore broadcast ICMP (mitigate SMURF)
      "net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault true;

      # Ignore incoming ICMP redirects (note: default is needed to ensure that the
      # setting is applied to interfaces added after the sysctls are set)
      "net.ipv4.conf.all.accept_redirects" = mkDefault false;
      "net.ipv4.conf.all.secure_redirects" = mkDefault false;
      "net.ipv4.conf.default.accept_redirects" = mkDefault false;
      "net.ipv4.conf.default.secure_redirects" = mkDefault false;
      "net.ipv6.conf.all.accept_redirects" = mkDefault false;
      "net.ipv6.conf.default.accept_redirects" = mkDefault false;

      # Ignore outgoing ICMP redirects (this is ipv4 only)
      "net.ipv4.conf.all.send_redirects" = mkDefault false;
      "net.ipv4.conf.default.send_redirects" = mkDefault false;
    };

    # SYSTEM PACKAGES
    environment.systemPackages = with pkgs; [
      bash
      wget
      curl
      nano
      kate
      ripgrep
      fd
    ];

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
