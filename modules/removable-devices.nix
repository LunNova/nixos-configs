{ ... }:
{
  config = {
    systemd.network.links."10-en-usb-8cd8" = {
      matchConfig.PermanentMACAddress = "8c:ae:4c:dd:20:d8";
      linkConfig.Name = "en-usb-8cd8";
    };

    # Disable suspend for USB network RTL8156
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", TEST=="power/control", ATTR{power/control}="on"
    '';
  };
}
