{ config, pkgs, lib, ... }:
let
  cfg = config.lun.power-saving;
in
{
  options.lun.power-saving = {
    enable = lib.mkEnableOption "Enable power saving configs";
    usb = lib.mkEnableOption "Enable USB power saving configs (tends to break some peripherals so only use on laptops?)";
  };
  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "iwlwifi.power_save=1"
      # increase usb autosuspend delay
      "usbcore.autosuspend=30"
    ];

    services.udev.extraRules = lib.mkMerge [
      ''
        # enable power control for all PCI devices
        SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"
        SUBSYSTEM=="pci", TEST=="d3cold_allowed", ATTR{d3cold_allowed}="1"

        # Enable power savings for scsi_host (/dev/s*) drives
        ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"

        # power saving for ata devices
        ACTION=="add", SUBSYSTEM=="ata_port", KERNEL=="ata*", TEST=="../../power/control" ATTR{../../power/control}="auto"

        # misc
        ATTR{power/async}=="disabled", ATTR{power/async}="enabled"
        # this is either a on/off switch or a timeout in seconds depending on the module
        # gets set to 10 later for snd_hda_intel which uses it as seconds timeout
        TEST=="parameters/power_save", ATTR{parameters/power_save}="1"
        TEST=="parameters/power_save_controller", ATTR{parameters/power_save_controller}="Y"

        # wifi power saving
        ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save on"

        # Enable power save mode for Intel HDA
        ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/snd_hda_intel", \
        RUN="${pkgs.bash}/bin/bash -c 'cd /sys/module/snd_hda_intel/parameters; \
        echo 10 > power_save; echo Y > power_save_controller'"
      ''
      (lib.mkIf cfg.usb ''
        # enable power control for all USB devices except multifunction, HID and hubs (00, 03, 09)
        # https://www.usb.org/defined-class-codes
        SUBSYSTEM=="usb", TEST=="power/control", \
          ATTR{bInterfaceClass}!="00", ATTR{bInterfaceClass}!="03", ATTR{bInterfaceClass}!="09", \
          ATTR{bDeviceClass}!="00", ATTR{bDeviceClass}!="03", ATTR{bDeviceClass}!="09", \
          ATTR{power/control}="auto"
        SUBSYSTEM=="usb", TEST=="power/control", \
          ENV{ID_USB_INTERFACES}!="", ENV{ID_USB_INTERFACES}!=":03*", ENV{ID_USB_INTERFACES}!=":09*" \
          ATTR{bDeviceClass}=="00", \
          ATTR{power/control}="auto"
      '')
    ];
  };
}
