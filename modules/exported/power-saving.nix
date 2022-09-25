{ config, pkgs, lib, ... }:
let
  cfg = config.lun.power-saving;
in
{
  options.lun.power-saving = {
    enable = lib.mkEnableOption "Enable power saving configs";
  };
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # enable power control for all PCI devices
      SUBSYSTEM=="pci", ATTR{power/control}="auto"
      # enable power control for all USB devices
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
      # Enable power save mode for Intel HDA
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/snd_hda_intel", \
      RUN="${pkgs.bash}/bin/bash -c 'cd /sys/module/snd_hda_intel/parameters; \
      echo 10 > power_save; echo Y > power_save_controller'"
    '';
  };
}
