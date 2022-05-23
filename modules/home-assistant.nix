{ pkgs, lib, config, ... }:
let cfg = config.lun.home-assistant; in
{
  options = {
    lun.home-assistant.enable = lib.mkEnableOption "enable HA containers";
  };
  config = lib.mkIf cfg.enable {
    lun.persistence.dirs = [ "/var/lib/home-assistant" ];

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = [ "/var/lib/home-assistant/main:/config" ];
        environment.TZ = "Europe/Berlin";
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [
          "--network=host"
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"
        ];
      };
      containers.homeassistant-zwave = {
        volumes = [ "/var/lib/home-assistant/zwave:/usr/src/app/store" ];
        environment.TZ = "Europe/Berlin";
        image = "zwavejs/zwavejs2mqtt:latest";
        extraOptions = [
          "--network=host"
          "--device=/dev/serial/by-id/usb-Silicon_Labs_Zooz_ZST10_700_Z-Wave_Stick_0001-if00-port0:/dev/zwave"
        ];
      };
    };
  };
}
