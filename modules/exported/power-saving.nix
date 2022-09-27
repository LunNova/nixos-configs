{ config, pkgs, lib, ... }:
let
  cfg = config.lun.power-saving;
in
{
  options.lun.power-saving = {
    enable = lib.mkEnableOption "Enable power saving configs";
  };
  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "iwlwifi.power_save=1"
      # increase usb autosuspend delay
      "usbcore.autosuspend=30"
    ];

    /*
      $ echo manual | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level
      manual
      lun@hisame ~ ./rw
      $ echo manual | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
      manual
      lun@hisame ~ ./rw
      $ echo 5 | sudo tee /sys/class/drm/card1/device/pp_power_profile_mode
      5
      lun@hisame ~ ./rw
      $ echo 5 | sudo tee /sys/class/drm/card0/device/pp_power_profile_mode
      5
      lun@hisame ~ ./rw
      $ cat /sys/class/drm/card1/device/pp_power_profile_mode
    */

    services.udev.extraRules = ''
      # enable power control for all PCI devices
      SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"
      # amdgpu power saving
      SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="manual"
      SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_state}="battery"
      SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/pp_power_profile_mode}="2"

      # enable power control for all USB devices except HID and hubs (03, 09)
      # https://www.usb.org/defined-class-codes
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bInterfaceClass}!="03", ATTR{bInterfaceClass}!="09", ATTR{power/control}="auto"

      # Enable power savings for scsi_host (/dev/s*) drives
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"

      # wifi power saving
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save on"

      # Enable power save mode for Intel HDA
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/snd_hda_intel", \
      RUN="${pkgs.bash}/bin/bash -c 'cd /sys/module/snd_hda_intel/parameters; \
      echo 10 > power_save; echo Y > power_save_controller'"
    '';
  };
}
