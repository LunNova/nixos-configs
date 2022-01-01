{ ... }:
let syncThingPort = 22000; in
{
  config.networking.firewall.allowedUDPPorts = [ syncThingPort ];
  config.networking.firewall.allowedTCPPorts = [ syncThingPort ];
}
