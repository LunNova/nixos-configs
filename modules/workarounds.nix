{ pkgs, ... }:
{
  config = {
    # networkd just stops managing my wlan0 after some generation changes #195777
    # https://github.com/NixOS/nixpkgs/issues/195777#issuecomment-1633546490
    # FIXME: kosame resets display-manager when this is used
    # system.activationScripts = {
    #   restart-udev = ''
    #     ${pkgs.systemd}/bin/systemctl restart systemd-udev-trigger.service
    #   '';
    # };
  };
}
