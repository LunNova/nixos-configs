{ pkgs, lib, config, ... }:
{
  options.lun.print.enable = lib.mkEnableOption "Enable printing and scanning";
  config = lib.mkIf config.lun.print.enable {
    services.printing.enable = true;
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };
}
