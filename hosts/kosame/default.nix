# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  kernelPackages = pkgs.linuxPackages_latest;
  kernel = kernelPackages.kernel;
in

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "lun-kosame-nixos";
  sconfig.machineId = "0715dc6a95b3419e8e2465240b7e598b";
  system.stateVersion = "21.05";

  services.xserver.videoDrivers = lib.mkDefault [ "amdgpu" ];

  # remove nvidia devices if not using nvidia config
  services.udev.extraRules = pkgs.lib.mkIf (!config.sconfig.amd-nvidia-laptop.enable) ''
    # Remove nVidia devices, when present.
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{remove}="1"
    #'';

  specialisation.nvidia.configuration = {
    sconfig.amd-nvidia-laptop.enable = true;
  };

  specialisation.wayland-test.configuration =
    let
      # https://github.com/cole-mickens/nixcfg/blob/main/mixins/nvidia.nix
      waylandEnv = { WLR_NO_HARDWARE_CURSORS = "1"; };
      nvidia-wlroots-overlay = (final: prev: {
        wlroots = prev.wlroots.overrideAttrs (old: {
          # HACK: https://forums.developer.nvidia.com/t/nvidia-495-does-not-advertise-ar24-xr24-as-shm-formats-as-required-by-wayland-wlroots/194651
          postPatch = ''
            sed -i 's/assert(argb8888 &&/assert(true || argb8888 ||/g' 'render/wlr_renderer.c'
          '';
        });
      });
      prime-run = pkgs.writeShellScriptBin "prime-run" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec -a "$0" "$@"
      '';
    in
    {
      services.xserver.videoDrivers = lib.mkForce [ "nvidia" "amdgpu" ];

      environment.systemPackages = with pkgs; [
        prime-run
        glxinfo
      ];

      nixpkgs.overlays = [ nvidia-wlroots-overlay ];

      environment.variables = waylandEnv;
      environment.sessionVariables = waylandEnv;

      hardware.nvidia.modesetting.enable = true;

      services.xserver.autorun = false;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.displayManager.gdm.wayland = true;
      services.xserver.displayManager.gdm.nvidiaWayland = true;

      services.xserver.desktopManager.gnome.enable = true;
      services.xserver.desktopManager.xfce.enable = true;
      services.xserver.displayManager.sddm.enable = lib.mkForce false;
      # https://github.com/NixOS/nixpkgs/issues/75867
      programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.gnome.seahorse.out}/libexec/seahorse/ssh-askpass";

      #services.xserver.desktopManager.plasma5.enable = lib.mkForce false;
      services.xserver.displayManager.sessionPackages = [
        (pkgs.plasma-workspace.overrideAttrs
          (old: { passthru.providedSessions = [ "plasmawayland" ]; }))
      ];


      # environment.systemPackages = with pkgs; [
      #   greetd.tuigreet
      # ];

      qt5.enable = true;
      qt5.platformTheme = "gtk2";
      qt5.style = "gtk2";

      services.dbus.packages = with pkgs; [ gnome3.dconf ];
      programs.light.enable = true;
      programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true; # so that gtk works properly
        extraPackages = with pkgs; [
          swaylock
          swayidle
          wl-clipboard
          mako # notification daemon
          alacritty # Alacritty is the default terminal in the config
          dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
          kanshi # sway monitor settings / autorandr equivalent? https://github.com/RaitoBezarius/nixos-x230/blob/764d2237ab59ded81492b6c76bc29da027e9fdb3/sway.nix example using it
        ];
      };

      hardware.opengl = {
        extraPackages = [
          pkgs.amdvlk
          pkgs.mesa.drivers
        ];
        extraPackages32 = [
          pkgs.driversi686Linux.amdvlk
          pkgs.pkgsi686Linux.mesa.drivers
        ];
      };

      # services.greetd = {
      #   enable = true;
      #   settings = {
      #     default_session = {
      #       command = "${lib.makeBinPath [pkgs.greetd.tuigreet] }/tuigreet --time --cmd sway";
      #       user = "greeter";
      #     };
      #   };
      # };
    };


  # Use the systemd-boot EFI boot loader.
  boot.kernelParams = [
    "mitigations=off"
  ];


  # Used to set power profiles, should have support in asus-wmi https://asus-linux.org/blog/updates-2021-07-16/
  services.power-profiles-daemon.enable = true;
  # Zephyrus G14: without it get 2h battery life idle, with like 6h idle
  # runs powertop --auto-tune at boot
  powerManagement.powertop.enable = true;

  # Configure keymap in X11
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;
}

