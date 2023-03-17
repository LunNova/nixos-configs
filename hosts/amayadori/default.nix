{ config, pkgs, lib, nixos-hardware-modules-path, ... }:

let
  # https://github.com/cole-mickens/nixcfg/blob/main/mixins/nvidia.nix
  waylandEnv = {
    WLR_RENDERER = "vulkan";
    VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
    # KWIN_OPENGL_INTERFACE = "egl";
    #    KWIN_EXPLICIT_SYNC = "0";
    #    KWIN_DRM_USE_MODIFIERS = "1";
    #    KWIN_DRM_FORCE_EGL_STREAMS = "0";
    # https://lamarque-lvs.blogspot.com/2021/12/nvidia-optimus-with-wayland-help-needed.html
    #WLR_NO_HARDWARE_CURSORS = "1";
    #KWIN_DRM_DEVICES = drmDevices;
    #WLR_DRM_DEVICES = drmDevices;
    #GBM_BACKEND = "nvidia-drm";
    #GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
    #__GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # https://github.com/NVIDIA/libglvnd/blob/master/src/EGL/icd_enumeration.md
    # https://github.com/NixOS/nixpkgs/blob/a0dbe47318bbab7559ffbfa7c4872a517833409f/pkgs/development/libraries/libglvnd/default.nix#L33
    #__EGL_VENDOR_LIBRARY_CONFIG_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d/";
    #__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS = "/etc/egl/egl_external_platform.d/:/run/opengl-driver/share/egl/egl_external_platform.d/";
  };
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./x13.nix
    ];

  lun.power-saving.enable = false;
  lun.power-saving.usb = false;
  lun.persistence.enable = true;
  lun.conservative-governor.enable = true;

  boot.plymouth.enable = lib.mkForce false;

  networking.hostName = "lun-amayadori-nixos";
  sconfig.machineId = "1f3c8ec5230e763537ec8ef5836f334a";
  system.stateVersion = "23.05";
  boot.cleanTmpDir = true;

  systemd.sleep.extraConfig = ''
    AllowHibernation=yes
    AllowSuspend=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  environment.variables = waylandEnv;
  environment.sessionVariables = waylandEnv;

  boot.kernelParams = [
    #    "mem_sleep_default=deep" # S3 by default
    #    "nmi_watchdog=0"
    #    "nowatchdog"
  ];

  # Used to set power profiles, should have support in asus-wmi https://asus-linux.org/blog/updates-2021-07-16/
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;
  # services.tlp.enable = true;

  # defaults to 16 on this machine which OOMs some builds
  nix.settings.cores = 8;
}

