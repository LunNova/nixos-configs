{ config, pkgs, lib, ... }:
{
  config = {
    my.home-manager.enabled-users = [ "lun" ];
    sconfig.yubikey = true; # modules/yubikey
    sconfig.input-remapper = true; # modules/input-remapper
    sconfig.tty12-journal.enable = true;

    # LANGUAGE / I18N
    i18n = let locale = "en_US.UTF-8"; in
      {
        defaultLocale = locale;
        supportedLocales = [ "${locale}/UTF-8" ];
      };
    time = {
      timeZone = "America/Los_Angeles";
      hardwareClockInLocalTime = true;
    };
    services.xserver.layout = "us";

    # CONSOLE
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };
    # Persist console when getty starts
    systemd.services."getty@".serviceConfig.TTYVTDisallocate = "no";

    # DISPLAYS
    hardware.video.hidpi.enable = false;

    # LOGGING
    services.journald.extraConfig = ''
      SystemMaxUse=500M
      MaxFileSec=1day
      MaxRetentionSec=1month
    '';

    # NIX
    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nixUnstable;
      daemonCPUSchedPolicy = "idle";
      extraOptions = lib.mkMerge [
        "experimental-features = nix-command flakes ca-derivations"
        "warn-dirty = false"
      ];
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
      # TODO: ssh-keygen -A at boot so these get generated while still using startWhenNeeded?
      # Maybe should always pregen when setting up a new system because will be using agenix later so this is irrelevant
      startWhenNeeded = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
      extraConfig = "UsePAM no";
      banner = "This computer system may not be used for any purpose.\nBe gay, do crime.\n";
    };
    lun.persistence.dirs = [ "/etc/ssh" ];

    # BOOT
    boot = {
      initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-amd" "kvm-intel" ];
      extraModulePackages = [ ];
    };

    # HARDWARE
    hardware = {
      enableRedistributableFirmware = true;
    };
    services.fstrim.enable = true;

    # HARDENING
    nix.allowedUsers = [ "@users" ];
    security = {
      sudo.execWheelOnly = true;
    };
    # https://github.com/NixOS/nixpkgs/blob/d6fe32c6b9059a054ca0cda9a2bb99753d1134df/nixos/modules/profiles/hardened.nix#L95
    boot.kernel.sysctl = with lib; {
      "kernel.sysrq" = 1; #allow all sysrqs
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
      killall
      traceroute
      dnsutils
      libfaketime
      lun.lun-scripts
    ];

    # DESKTOP ENV
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = false;
    xdg.portal.gtkUsePortal = true; # Use xdg-desktop-portal for file pickers
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.gdm.wayland = true;
    services.xserver.displayManager.gdm.nvidiaWayland = true;
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.desktopManager.plasma5.runUsingSystemd = true;

    # SOUND
    sound.enable = false;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      media-session.enable = false;
      wireplumber.enable = true;
      jack.enable = false;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      lowLatency.enable = true;
    };
    hardware.bluetooth.enable = true;

    # GRAPHICS ACCEL
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # BLUETOOTH
    services.blueman.enable = true;

    # CHECKS
    assertions = [
      {
        assertion = config.hardware.cpu.amd.updateMicrocode || config.hardware.cpu.intel.updateMicrocode;
        message = "updateMicrocode should be set for intel or amd";
      }
    ];
  };
}
