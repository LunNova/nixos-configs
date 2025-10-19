{
  services.resolved = {
    enable = true;
    llmnr = "true";
    dnssec = "false";
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
  services.nscd.enableNsncd = true;
}
