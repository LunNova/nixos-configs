{ pkgs, ... }:
{
  config = {
    services.printing.enable = true;
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };
}
