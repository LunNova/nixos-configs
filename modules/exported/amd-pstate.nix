{ config, lib, ... }:
let
  cfg = config.lun.amd-pstate;
in
{
  options.lun.amd-pstate = {
    enable = lib.mkEnableOption "Enable AMD memory encryption";
    sharedMem = lib.mkEnableOption "use shared_mem";
  };
  config = lib.mkIf cfg.enable {
    # If won't load try sudo modprobe amd_pstate dyndbg==pmf shared_mem=1 -v
    # then check dmesg for error

    # If missing _CPC in SBIOS error:
    # amd_pstate:amd_pstate_init: amd_pstate: the _CPC object is not present in SBIOS
    # option can be found here: Advanced > AMD CBS > NBIOS Common Options > SMU Common Options > CPPC > CPPC CTRL set to Enabled
    boot = {
      kernelParams = lib.mkMerge [
        [
          "initcall_blacklist=acpi_cpufreq_init" # use amd_pstate instead
        ]
        (lib.mkIf cfg.sharedMem [ "amd_pstate.shared_mem=1" ])
      ];
      initrd.kernelModules = [ "amd_pstate" ];
      # kernelPatches = [
      #   {
      #     name = "enable-amd-sme-sev";
      #     patch = null;
      #     extraStructuredConfig = with lib.kernel; {
      #       AMD_MEM_ENCRYPT = yes;
      #       AMD_MEM_ENCRYPT_ACTIVE_BY_DEFAULT = yes;
      #     };
      #   }
      # ];
    };

    system.requiredKernelConfig = with config.lib.kernelConfig; [
      ((isYes "X86_AMD_PSTATE") or isModule "X86_AMD_PSTATE")
    ];
  };
}
