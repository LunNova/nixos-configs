{ config, lib, pkgs, ... }:
let
  cfg = config.lun.conservative-governor;
in
{
  options.lun.conservative-governor = {
    enable = lib.mkEnableOption "conservative cpufreq governor";
  };
  config = lib.mkIf cfg.enable
    {
      boot.kernelModules = [ "cpufreq_conservative" ];
      powerManagement.cpuFreqGovernor = "schedutil";

      services.udev.extraRules = ''
        # make conservative governer snappier to scale up
        # and ignore niced loads for scaling
        KERNEL=="cpu", \
          RUN+="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/echo 20 > /sys/devices/system/cpu/cpufreq/conservative/freq_step'" \
          RUN+="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/echo 1 > /sys/devices/system/cpu/cpufreq/conservative/ignore_nice_load'"
      '';
    };
}
