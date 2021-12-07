{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "lun-amaya-nixos";
    networking.hostId = "ad97aa3e";

    hardware.cpu.amd.updateMicrocode = true;

    my.home-manager.enabled-users = [ "lun" ];
  };
}
