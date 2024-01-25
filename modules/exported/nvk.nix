{ config, lib, flakeArgs, ... }:
let
  cfg = config.lun.nvk;
  env = {
    NVK_I_WANT_A_BROKEN_VULKAN_DRIVER = "1";
    MESA_VK_VERSION_OVERRIDE = "1.3";
    # GALLIUM_DRIVER = "zink";
    # __GLX_VENDOR_LIBRARY_NAME = "mesa";
    # MESA_LOADER_DRIVER_OVERRIDE = "zink";
    WLR_RENDERER = "vulkan";
  };
  mesa = import "${flakeArgs.self}/mesa/"; # mesaOverride pkgs.mesa;
  # mesa-i686 = pkgs.pkgsi686Linux.callPackage "${flakeArgs.self}/mesa/" { };
  # mesa = mesaOverride pkgs.mesa;
  # mesa-i686 = mesaOverride pkgs.pkgsi686Linux.mesa;
in
{
  options.lun.nvk = {
    enable = lib.mkEnableOption "nvk experimental module";
  };
  config = lib.mkIf cfg.enable {
    boot.blacklistedKernelModules = [ "nvidia" "nvidia_uvm" ];
    boot.kernelModules = [ "nouveau" ];
    boot.kernelParams = [
      "nouveau.config=NvGspRm=1"
      "nouveau.debug=info,VBIOS=info,gsp=debug"

      #"loglevel=6"
      #"drm.debug=2"
    ];
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
    environment.sessionVariables = env;
    environment.variables = env;
    # hardware.opengl = lib.mkForce {
    #   package = mesa.drivers;
    #   package32 = mesa-i686.drivers;
    # };

    nixpkgs.overlays = [
      mesa.overlay
    ];
    #   system.replaceRuntimeDependencies = [
    #     {
    #       original = pkgs.mesa;
    #       replacement = mesa;
    #     }
    #     {
    #       original = pkgs.mesa.drivers;
    #       replacement = mesa.drivers;
    #     }
    #     {
    #       original = pkgs.pkgsi686Linux.mesa;
    #       replacement = mesa-i686;
    #     }
    #     {
    #       original = pkgs.pkgsi686Linux.mesa.drivers;
    #       replacement = mesa-i686.drivers;
    #     }
    #   ];
  };
}
