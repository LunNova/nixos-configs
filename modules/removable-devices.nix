{ config, pkgs, lib, ... }:
{
  config = {
    systemd.network.links."10-en-usb-8cd8" = {
      matchConfig.PermanentMACAddress = "8c:ae:4c:dd:20:d8";
      linkConfig.Name = "en-usb-8cd8";
    };
  };
}

  
