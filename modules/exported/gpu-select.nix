{ pkgs, lib, config, ... }:
let
  cfg = config.lun.gpu-select;
  env = {
    # gets checked by our patched X
    KMS_DEVICE = "/dev/dri/${cfg.card}";
    # gets checked by KDE's kwin wayland compositor
    KWIN_DRM_DEVICES = "/dev/dri/${cfg.card}";
    # makes mesa's device select layer expose only the default device
    # this will be the selected card usually, or if DRI_PRIME is set the first GPU in the system that isn't that and isn't CPU
    MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE = "1";
  };
in
{
  options.lun.gpu-select = {
    card = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };
  config = lib.mkIf (cfg.card != null) {
    environment.variables = env;
    environment.sessionVariables = env;
    # Setting explicitly on displayManager service because wasn't picking them up for some reason
    systemd.services.displayManager.environment = env;

    # Adds support for KMS_DEVICE env var to ensure only one device is accessed by X server
    services.xserver.displayManager.xserverBin = lib.mkForce "${pkgs.lun.xorgserver.out}/bin/X";

    services.udev.extraRules = ''
      # ensure all cards don't get seat and master-of-seat tags
      SUBSYSTEM=="drm", KERNEL=="card[0-9]", TAG-="seat", TAG-="master-of-seat", ENV{ID_FOR_SEAT}="", ENV{ID_PATH}=""
      # adds seat, master-of-seat and mutter-device-preferred-primary tag for desired card
      # TODO: are there any other tags here used by other compositors?
      SUBSYSTEM=="drm", KERNEL=="${cfg.card}", TAG+="seat", TAG+="master-of-seat", TAG+="mutter-device-preferred-primary"
    '';
  };
}
