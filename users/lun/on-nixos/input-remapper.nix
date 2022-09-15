{ lib, nixosConfig, ... }:
{
  home.file.".config/autostart/input-remapper-autoload.desktop" = lib.mkIf nixosConfig.services.input-remapper.enable {
    source = "${nixosConfig.services.input-remapper.package}/share/applications/input-remapper-autoload.desktop";
  };
}
