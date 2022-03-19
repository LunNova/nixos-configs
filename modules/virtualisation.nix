{ pkgs, ... }:
{
  config = {
    virtualisation.docker.enable = true;
    lun.persistence.dirs = [ "/var/lib/docker" ];

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
