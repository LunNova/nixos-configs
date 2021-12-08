# Copied from github:buckley310/nixos-config, MIT
{ config, lib, ... }:
let
  cfg = config.sconfig.machineId;
in
{
  options.sconfig.machineId = with lib; mkOption {
    type = with types; nullOr (strMatching "[0-9a-f]+");
    default = null;
  };
  config = {
    environment.etc."machine-id".text = cfg;
    # MACHINE ID
    networking.hostId = lib.mkIf (cfg != null) (builtins.substring 0 8 cfg);

    assertions = [
      {
        assertion = cfg != null;
        message = "Set the environment.etc.\"machine-id\" option. Use `od -vN 16 -An -tx1 /dev/urandom | tr -d \" \"` to generate.";
      }
      {
        assertion = config.networking.hostId != null;
        message = "Set the networking.hostId option. Use `od -vN 4 -An -tx1 /dev/urandom | tr -d \" \"` to generate.";
      }
    ];
  };
}
