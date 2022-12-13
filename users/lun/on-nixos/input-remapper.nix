{ lib, nixosConfig, ... }:
{
  xdg.configFile."autostart/input-mapper-autoload.desktop" = lib.mkIf nixosConfig.services.input-remapper.enable {
    source = "${nixosConfig.services.input-remapper.package}/share/applications/input-remapper-autoload.desktop";
  };
}
