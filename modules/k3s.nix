{ config, pkgs, lib, ... }:
let
  cfg = config.lun.k3s;
in
{
  options.lun.k3s = {
    enable = lib.mkEnableOption "k3s cluster node";

    role = lib.mkOption {
      type = lib.types.enum [ "server" "agent" ];
      description = "Whether this node is a k3s server or agent.";
    };

    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The k3s server URL to join (required for agents).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.k3s = {
      enable = true;
      inherit (cfg) role serverAddr;
      tokenFile = "/persist/secrets/k3s-token";
      disable = lib.mkIf (cfg.role == "server") [ "traefik" "metrics-server" "servicelb" ];
      extraFlags = lib.optionals (cfg.role == "server") [
        "--write-kubeconfig-mode"
        "0644"
      ];
    };

    environment.systemPackages = [ pkgs.socat ];

    boot.kernelModules = [ "fuse" ];

    lun.persistence.dirs = [
      "/var/lib/rancher/k3s"
      "/etc/rancher"
    ];

    networking.firewall = lib.mkMerge [
      {
        allowedUDPPorts = [ 8472 ];
        allowedTCPPortRanges = [{ from = 30000; to = 32767; }];
      }
      (lib.mkIf (cfg.role == "server") {
        allowedTCPPorts = [ 6443 ];
      })
    ];
  };
}
