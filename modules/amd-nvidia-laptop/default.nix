{ config, lib, pkgs, ... }:
let
  cfg = config.sconfig.amd-nvidia-laptop;
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
  };
}
