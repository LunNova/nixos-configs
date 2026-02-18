{ pkgs
, lib
, nixosConfig ? null
, ...
}:
{
  config = {
    home.packages = [
      pkgs.qdirstat
      pkgs.kdePackages.dolphin
    ];

    services.udiskie.enable = lib.mkIf (nixosConfig != null && nixosConfig.services.udisks2.enable) true;
  };
}
