{ config, lib, pkgs, ... }:
let
  cfg = config.sconfig.amd-nvidia-laptop;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  options.sconfig.amd-nvidia-laptop = {
    enable = lib.mkEnableOption "Enable amd-nvidia-laptop";
    prime = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    environment.systemPackages = [ (lib.mkIf cfg.prime nvidia-offload) ];
    hardware.nvidia = lib.mkIf cfg.prime {
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
  };
}
