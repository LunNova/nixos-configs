# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, mach-nix, ... }:

let
  nvidia = true;
  nvidiaPrime = false;
  kernelPackages = pkgs.linuxPackages_latest;
  kernel = kernelPackages.kernel;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  services.xserver.videoDrivers = if nvidia then [ "nvidia" ] else [ "amdgpu" ];

  fileSystems."/" = { options = [ "noatime" "nodiratime" ]; };
  services.fstrim = { enable = true; interval = "weekly"; };

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "mitigations=off" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  systemd.extraConfig = "DefaultTimeoutStopSec=10s";

  networking.hostName = "lun-laptop-1-nixos"; # Define your hostname.

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.resolvconf.dnsExtensionMechanism = false;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  #networking.interfaces.en-usb-0.useDHCP = true;
  #networking.interfaces.en-wlan-0.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  # mouse accel off for kde - doesn't exist
  #services.xserver.desktopManager.plasma5.kcminputrc.XLbInptAccelProfileFlat=true;
  #services.xserver.useGlamor = true;
  #services.xserver.displayManager.sddm.settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
  services.xserver.desktopManager.plasma5.runUsingSystemd = true;
  services.xserver.displayManager.sessionPackages = [
    (pkgs.plasma-workspace.overrideAttrs
      (old: { passthru.providedSessions = [ "plasmawayland" ]; }))
  ];

  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  sconfig.scroll-boost = true; # modules/scroll-boost
  sconfig.yubikey = true; # modules/yubikey

  services.xserver.libinput = {
    # Enable touchpad/mouse
    enable = true;
    # Disable mouse accel
    mouse = { accelProfile = "flat"; };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lun = {
    isNormalUser = true;
    # Change after install
    initialPassword = "nix-placeholder";
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "plugdev" # openrazer requires this
      "openrazer"
      "docker"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    firefox
    nano
    kate
    ripgrep
    neovim
    fd
    (pkgs.lib.mkIf nvidiaPrime nvidia-offload)
    my.key-mapper
  ];

  hardware.openrazer.enable = true;

  hardware.nvidia = pkgs.lib.mkIf nvidiaPrime {
    modesetting.enable = false;
    #powerManagement.enable = true;
    #powerManagement.finegrained = true;
    #nvidiaPersistenced = true;
    #package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    prime = {
      amdgpuBusId = "PCI:4:0:0";
      nvidiaBusId = "PCI:1:0:0";
      offload.enable = true;
      #sync.enable = true;  # Do all rendering on the dGPU
    };
  };

  systemd.services.display-manager.after = pkgs.lib.mkIf nvidia [ "dev-dri-card0.device" "dev-dri-card1.device" ];
  systemd.services.display-manager.wants = pkgs.lib.mkIf nvidia [ "dev-dri-card0.device" "dev-dri-card1.device" ];

  # https://wiki.archlinux.org/title/NVIDIA/Troubleshooting#Xorg_fails_during_boot,_but_otherwise_starts_fine
  services.udev.packages = pkgs.lib.mkIf nvidia [
    (pkgs.writeTextFile {
      name = "dri_device_udev";
      text = ''
        ACTION=="add", KERNEL=="card*", SUBSYSTEM=="drm", TAG+="systemd"
      '';

      destination = "/etc/udev/rules.d/99-systemd-dri-devices.rules";
    })
  ];
  services.udev.extraRules = pkgs.lib.mkIf (!nvidia) ''
    # Remove nVidia devices, when present.
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{remove}="1"
    #'';

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  programs.steam.enable = true;
}

