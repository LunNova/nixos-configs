{ lib, config, ... }:
let cfg = config.lun.home-assistant; in
{
  options = {
    lun.home-assistant.enable = lib.mkEnableOption "enable HA containers";
  };
  config = lib.mkIf cfg.enable {
    lun.persistence.dirs = [ "/var/lib/home-assistant" ];

    systemd.services.podman.after = [ "NetworkManager-wait-online.service" ];
    systemd.services.podman.wants = [ "NetworkManager-wait-online.service" ];

    virtualisation.oci-containers = {
      containers.homeassistant = {
        volumes = [ "/var/lib/home-assistant/main:/config" ];
        environment.TZ = "Europe/Berlin";
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [
          "--network=host"
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"
        ];
        # this is a bodge to ensure pyemvue is in the container
        # but I don't want to have to host my own ha container builds somewhere
        # and it's good enough for now
        entrypoint = "/bin/bash";
        cmd = [
          "-c"
          "set -e; sleep 1; /usr/local/bin/pip3 install 'pyemvue==0.15.*'; exec /init"
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
