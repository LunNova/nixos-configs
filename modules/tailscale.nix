{ config, pkgs, lib, ... }:
{
  config = {
    environment.systemPackages = [ pkgs.tailscale ];
    services.tailscale.enable = true;

    networking.firewall = {
      # always allow traffic from your Tailscale network
      trustedInterfaces = [ "tailscale0" ];

      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
}
