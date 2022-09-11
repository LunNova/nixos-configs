{ pkgs, ... }:
{
  config = {
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
      virtmanager
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
