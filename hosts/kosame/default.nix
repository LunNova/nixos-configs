# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, nixos-hardware-modules-path, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #"${nixos-hardware-modules-path}/asus/battery.nix"
    ];

  # TODO report issue, not reliable
  # hardware.asus.battery.chargeUpto = 70;
  systemd.services.battery-charge-threshold = {
    wantedBy = [ "multi-user.target" "suspend.target" ];
    after = [ "multi-user.target" "suspend.target" ];
    description = "Set the battery charge threshold";
    startLimitBurst = 70;
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      ExecStart = "/bin/sh -c 'echo 70 > /sys/class/power_supply/BAT0/charge_control_end_threshold'";
    };
  };

  networking.hostName = "lun-kosame-nixos";
  sconfig.machineId = "0715dc6a95b3419e8e2465240b7e598b";
  system.stateVersion = "21.05";
  boot.cleanTmpDir = true;
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod;

  services.xserver.videoDrivers = lib.mkDefault [ "amdgpu" ];

  # TODO: Remove after https://github.com/NixOS/nixpkgs/pull/153091
  hardware.opengl = {
    package = lib.mkForce pkgs.mesa.drivers;
    package32 = lib.mkForce pkgs.pkgsi686Linux.mesa.drivers;
    # Optionally add amdvlk - IME mesa works better
    extraPackages = [
      pkgs.libglvnd
      (pkgs.hiPrio config.hardware.nvidia.package.out)
    ];
    extraPackages32 = [
      pkgs.pkgsi686Linux.libglvnd
      (pkgs.hiPrio config.hardware.nvidia.package.lib32)
    ];
  };

  # remove nvidia devices if not using nvidia config
  services.udev.extraRules = pkgs.lib.mkIf (!config.sconfig.amd-nvidia-laptop.enable) ''
    # Remove nVidia devices, when present.
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{remove}="1"
    #'';

  systemd.sleep.extraConfig = ''
    AllowHibernation=no
    AllowSuspend=yes
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  specialisation.nvidia.configuration = {
    sconfig.amd-nvidia-laptop.enable = true;
  };

  environment.systemPackages = lib.mkIf (pkgs.plasma5Packages.plasma5.kwin == pkgs.kwinft.kwin) [ pkgs.kwinft.disman pkgs.kwinft.kdisplay ];

  specialisation.wayland-test.configuration =
    let
      drmDevices = "/dev/dri/card0";
      # https://github.com/cole-mickens/nixcfg/blob/main/mixins/nvidia.nix
      waylandEnv = {
        WLR_RENDERER = "vulkan";
        VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
        # https://lamarque-lvs.blogspot.com/2021/12/nvidia-optimus-with-wayland-help-needed.html
        #WLR_NO_HARDWARE_CURSORS = "1";
        #KWIN_DRM_DEVICES = drmDevices;
        #WLR_DRM_DEVICES = drmDevices;
        #GBM_BACKEND = "nvidia-drm";
        #GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
        #__GLX_VENDOR_LIBRARY_NAME = "nvidia";
        #__VK_LAYER_NV_optimus = "NVIDIA_only";
        #__GL_VRR_ALLOWED = "0";
        #__GL_GSYNC_ALLOWED = "0";

        # https://github.com/NVIDIA/libglvnd/blob/master/src/EGL/icd_enumeration.md
        # https://github.com/NixOS/nixpkgs/blob/a0dbe47318bbab7559ffbfa7c4872a517833409f/pkgs/development/libraries/libglvnd/default.nix#L33
        #__EGL_VENDOR_LIBRARY_CONFIG_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d/";
        #__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS = "/etc/egl/egl_external_platform.d/:/run/opengl-driver/share/egl/egl_external_platform.d/";
      };
      prime-run = pkgs.writeShellScriptBin "prime-run" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec -a "$0" "$@"
      '';
    in
    {
      services.xserver.videoDrivers = lib.mkForce [ "nvidia" "amdgpu" ];
      boot.initrd.kernelModules = [ "nvidia" "nvidia_drm" "nvidia_modeset" ];
      #boot.blacklistedKernelModules = [ "amdgpu" "radeon" "nouveau" ];

      environment.systemPackages = with pkgs; [
        prime-run
        glxinfo
      ];

      environment.variables = waylandEnv;
      environment.sessionVariables = waylandEnv;

      hardware.nvidia.modesetting.enable = true;

      services.xserver.desktopManager.gnome.enable = true;
      # https://github.com/NixOS/nixpkgs/issues/75867
      programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.gnome.seahorse.out}/libexec/seahorse/ssh-askpass";

      #services.xserver.desktopManager.plasma5.enable = lib.mkForce false;
      services.xserver.displayManager.sessionPackages = [
        (pkgs.plasma-workspace.overrideAttrs
          (old: { passthru.providedSessions = [ "plasmawayland" ]; }))
      ];

      hardware.nvidia = {
        powerManagement.enable = true;
      };
      services.udev.extraRules = ''
        # Remove NVIDIA Audio devices, if present
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
        # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
        ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
        ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
        # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
        ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
        ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
      '';
      boot.extraModprobeConfig = ''
        options nvidia "NVreg_DynamicPowerManagement=0x02"
      '';

      powerManagement.powertop.enable = lib.mkForce false;

      services.dbus.packages = with pkgs; [ dconf ];
    };

  boot.kernelParams = [
    "mitigations=off"
    "mem_sleep_default=deep" # S3 by default
  ];
  # Enables S3 by replacing ACPI DSDT table with one which reports it
  boot.initrd.prepend = [ "${./acpi_override}" ];

  boot.blacklistedKernelModules = [ "radeon" "nouveau" ];

  # Used to set power profiles, should have support in asus-wmi https://asus-linux.org/blog/updates-2021-07-16/
  services.power-profiles-daemon.enable = true;
  # Zephyrus G14: without it get 2h battery life idle, with like 6h idle
  # runs powertop --auto-tune at boot
  powerManagement.powertop.enable = false;
}

