# Copied from github:buckley310/nixos-config, MIT
{ config, lib, ... }:
let
  cfg = config.lun.persistence;
  persistPath = config.lun.persistence.persistPath;
  addCheckDesc = desc: elemType: check: lib.types.addCheck elemType check
    // { description = "${elemType.description} (with check: ${desc})"; };
  isNonEmpty = s: (builtins.match "[ \t\n]*" s) == null;
  nonEmptyStr = addCheckDesc "non-empty" lib.types.str isNonEmpty;
  nonEmptyWithoutTrailingSlash = addCheckDesc "non-empty without trailing slash" lib.types.str
    (s: isNonEmpty s && (builtins.match ".+/" s) == null);
in
{
  options.lun.persistence = {
    enable = lib.mkEnableOption "Enable persistence module for tmpfs on root";

    persistPath = lib.mkOption {
      type = nonEmptyWithoutTrailingSlash;
      default = "/persist";
    };

    files = lib.mkOption {
      type = with lib.types; listOf nonEmptyWithoutTrailingSlash;
      default = [ ];
    };

    dirs = lib.mkOption {
      type = with lib.types; listOf nonEmptyWithoutTrailingSlash;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules =
      let escapedFiles = (builtins.map (path: lib.escape [ "\"" "\\" ] path) cfg.files);
      in
      (builtins.map (path: "L+ \"${path}\" - - - - ${persistPath}/${path}") escapedFiles);

    fileSystems = (builtins.listToAttrs (builtins.map (path: { name = path; value = { device = "${persistPath}/${path}"; noCheck = true; neededForBoot = true; options = [ "bind" ]; }; }) cfg.dirs));
  };
}
