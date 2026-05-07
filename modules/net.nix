{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      LLMNR = "true";
      DNSSEC = "false";
      FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
  services.nscd.enableNsncd = true;
}
