{ pkgs, config, lib, ... }:
{
  options.lun.virtualisation.enable = lib.mkEnableOption "virt" // { default = true; };
  config = lib.mkIf config.lun.virtualisation.enable {
    # Not using NixOS containers currently
    boot.enableContainers = false;

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true; # docker alias
      };
      oci-containers.backend = "podman";
    };

    lun.persistence.dirs = [
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
    ];

    environment.systemPackages = with pkgs; [
      virt-manager
      virtiofsd
    ];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        ovmf.enable = true;
        runAsRoot = false;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
  };
}
