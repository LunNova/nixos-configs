{ pkgs
, lib
, nixosConfig ? null
, ...
}:
{
  config = {
    home.packages = [
      pkgs.qdirstat
      pkgs.k4dirstat
      pkgs.dolphin
    ];

    services.udiskie.enable = lib.mkIf (nixosConfig != null && nixosConfig.services.udisks2.enable) true;
  };
}
