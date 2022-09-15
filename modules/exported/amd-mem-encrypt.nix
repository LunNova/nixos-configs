{ config, lib, ... }:
let
  cfg = config.lun.amd-mem-encrypt;
in
{
  options.lun.amd-mem-encrypt = {
    enable = lib.mkEnableOption "Enable AMD memory encryption";
  };
  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = [
        "kvm_amd.sev=1"
        "mem_encrypt=on"
      ];
      kernelPatches = [
        {
          name = "enable-amd-sme-sev";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            AMD_MEM_ENCRYPT = yes;
            AMD_MEM_ENCRYPT_ACTIVE_BY_DEFAULT = yes;
          };
        }
      ];
    };
  };
}
