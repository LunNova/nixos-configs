# Based off setup from github:buckley310/nixos-config although has diverged now
{ config, lib, ... }:
let
  cfg = config.lun.persistence;
  inherit (config.lun.persistence) persistPath;
  addCheckDesc = desc: elemType: check: lib.types.addCheck elemType check
    // { description = "${elemType.description} (with check: ${desc})"; };
  isNonEmpty = s: (builtins.match "[ \t\n]*" s) == null;
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
      let escapedFiles = builtins.map (lib.escape [ "\"" "\\" ]) cfg.files;
      in
      builtins.map (path: "L+ \"${path}\" - - - - ${persistPath}${path}") escapedFiles;

    fileSystems =
      let pathToFilesystem = name: { inherit name; value = { device = "${persistPath}/${name}"; noCheck = true; neededForBoot = true; options = [ "bind" ]; }; };
      in builtins.listToAttrs (builtins.map pathToFilesystem cfg.dirs);
  };
}
