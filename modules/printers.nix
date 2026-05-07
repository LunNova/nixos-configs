{ pkgs, lib, config, ... }:
{
  options.lun.print.enable = lib.mkEnableOption "Enable printing and scanning";
  config = lib.mkIf config.lun.print.enable {
    services.printing.enable = true;
    services.printing.drivers = [
      pkgs.epson-escpr2
    ];
    programs.system-config-printer.enable = true;
    # FIXME: hardware.sane + sane-airscan should work for scanning, but it don't
  };
}
