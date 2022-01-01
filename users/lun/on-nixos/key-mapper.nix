{ pkgs, lib, nixosConfig, ... }:
{
  home.file.".config/autostart/key-mapper-autoload.desktop" = lib.mkIf nixosConfig.sconfig.key-mapper {
    source = "${pkgs.lun.key-mapper}/share/applications/key-mapper-autoload.desktop";
  };
}
