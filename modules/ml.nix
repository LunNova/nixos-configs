{ config, lib, pkgs, ... }:
let
  cfg = config.lun.ml;
  virtualisation = config.virtualisation.podman.enable or config.virtualisation.docker.enable;
  nvidia = builtins.elem "nvidia" cfg.gpus;
  amd = builtins.elem "amd" cfg.gpus;
in
{
  options.lun.ml = {
    enable = lib.mkEnableOption "Enable ml";
    gpus = with lib; mkOption {
      type = with types; listOf (enum [ "nvidia" "amd" "intel" ]);
      description = "";
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (virtualisation && nvidia) {
      virtualisation.docker.enableNvidia = true;
      virtualisation.podman.enableNvidia = true;
      # https://github.com/NixOS/nixpkgs/issues/127146
      systemd.enableUnifiedCgroupHierarchy = false;
    })
    (lib.mkIf (virtualisation && amd) {
      # TODO: anything else needed?
      hardware.opengl.extraPackages = [
        pkgs.rocmPackages.rocm-opencl-icd
        pkgs.rocmPackages.rocm-opencl-runtime
        pkgs.rocmPackages.rocm-runtime
      ];
    })
  ]);
}
