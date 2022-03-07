{ config, lib, pkgs, ... }:
let
  cfg = config.lun.ml;
  virtualisation = config.virtualisation.docker.enable;
  nvidia = builtins.elem "nvidia" cfg.lun.ml.gpus;
  amd = builtins.elem "amd" cfg.lun.ml.gpus;
in
{
  options.lun.ml = {
    enable = lib.mkEnableOption "Enable ml";
    gpuVendors = with lib; mkOption {
      type = with types; listOf enum [ "nvidia" "amd" "intel" ];
      description = "";
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (virtualisation && nvidia) {
      virtualisation.docker.enableNvidia = true;
      # https://github.com/NixOS/nixpkgs/issues/127146
      systemd.enableUnifiedCgroupHierarchy = false;
    })
    (lib.mkIf (virtualisation && amd) {
      # TODO: anything else needed?
      hardware.opengl.extraPackages = [
        pkgs.rocm-opencl-icd
        pkgs.rocm-opencl-runtime
      ];
    })
  ]);
}
