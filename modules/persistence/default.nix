# Copied from github:buckley310/nixos-config, MIT
{ config, lib, ... }:
let
  cfg = config.lun.persistence;
in
{
  options.lun.persistence = {
    enable = lib.mkEnableOption "Enable persistence module for tmpfs on root";

    files = lib.mkOption {
      type = with lib.types; listOf string;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules =
      let escapedFiles = (builtins.map (path: lib.escape [ "\"" "\\" ] path) cfg.files);
      in
      (builtins.map (path: "L+ \"${path}\" - - - - /persist${path}") escapedFiles);
  };
}
