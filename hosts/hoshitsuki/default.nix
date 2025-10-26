{ config, flakeArgs, pkgs, lib, ... }:
let
  name = "hoshitsuki";
  swap = null; #"/dev/disk/by-partlabel/${name}_swap";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "nodiscard" ];
in
{
  imports = [
    ./disks.nix
    flakeArgs.disko.nixosModules.disko
  ];

  config = {
    networking.hostName = "${name}-nixos";
    sconfig.machineId = "94614f56e36298c0a1983c3afa13b6d6";
    system.stateVersion = "24.05";

    hardware.graphics.extraPackages = with pkgs; [
      amdvlk
      vulkan-loader
    ];

    services.atticd.enable = true;
    services.atticd.environmentFile = "/persist/attic-env";

    boot.kernelParams = [
      #"pci=pcie_bus_perf,big_root_window,ecrc=on"
      #"pcie_ports=native" # handle everything in linux even if uefi wants to
      #"pcie_port_pm=force" # force pm on even if not wanted by platform
      #"pcie_aspm=force" # force link state
      #"quiet"
      #"splash"
      "nosplash"

      # modinfo amdgpu | grep "^parm:"
      # "amdgpu.gpu_recovery=2" # advanced TDR mode
      # reset_method:GPU reset method (-1 = auto (default), 0 = legacy, 1 = mode0, 2 = mode1, 3 = mode2, 4 = baco/bamaco) (int)
      # "amdgpu.reset_method=4"

      # TODO: Move into amdgpu-no-ecc module
      # "amdgpu.ras_enable=0"
      "amdgpu.ppfeaturemask=0xffffffff" # enable all powerplay features to allow increasing power limit
      # 10s timeout for all operations (otherwise compute defaults to 60s)
      "amdgpu.lockup_timeout=10000,10000,10000,10000"
      "amdgpu.runpm=-2"
      "amdgpu.aspm=1"

      # trust tsc, modern AMD platform
      "tsc=nowatchdog"
      "iommu=pt"
      #"iommu=off" # AMD recommend disabling iommu for ML loads
      "amd_iommu=pgtbl_v2,force_enable"
      "amdgpu.send_sigterm=1"
      #"amdgpu.bapm=1"
      #"amdgpu.mes=1"
      #"amdgpu.uni_mes=1"
      "amdgpu.use_xgmi_p2p=1"
      "amdgpu.pcie_p2p=1"
      # https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/KernelParameters.md
      "acpi_enforce_resources=lax"
      "mem_encrypt=off"
    ];
    lun.power-saving.enable = true;
    services.udev.packages = [ pkgs.i2c-tools pkgs.openrgb-with-all-plugins ];
    environment.systemPackages = [ pkgs.i2c-tools pkgs.openrgb-with-all-plugins config.boot.kernelPackages.cpupower pkgs.dmidecode ];
    boot.kernelModules = [ "i2c-dev" "i2c-piix4" "i2c-smbus" "sp5100-tco" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    boot.kernelPatches = [
      # {
      #   name = "amdgpu-plimit-override";
      #   patch = ./amdgpu-plimit-override.patch;
      # }
      {
        name = "lun-cfg";
        patch = null;
        extraConfig = ''
          HSA_AMD y
          PCI_P2PDMA y
          DMABUF_MOVE_NOTIFY y
          HSA_AMD_P2P y
          PCI_SW_SWITCHTEC y
          FONT_TER16x32 n
        '';
      }
    ];
    lun.efi-tools.enable = true;
    services.nscd.enableNsncd = true;
    networking.firewall.allowedTCPPorts = [ 5000 5001 8000 8080 8081 ];
    # FIXME: swap to module if https://github.com/NixOS/nixpkgs/pull/427964/ gets merged
    systemd.services.cloudflared-tunnel = {
      startLimitBurst = 5;
      after = [
        "network.target"
        "network-online.target"
      ];
      wants = [
        "network.target"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        RuntimeDirectory = "cloudflared-tunnel-${name}";
        RuntimeDirectoryMode = "0400";
        LoadCredential = [ "credentials.json:/persist/var/cloudflared/tunnel-5747fa14" ];
        ExecStart = "${lib.getExe pkgs.cloudflared} tunnel run --token-file /run/credentials/cloudflared-tunnel.service/credentials.json";
        Restart = "on-failure";
        RestartSec = "1s";
        RestartMaxDelaySec = "30s";
        DynamicUser = true;
      };
    };
    programs.nix-ld.enable = true;

    systemd.defaultUnit = lib.mkForce "multi-user.target";
    boot.plymouth.enable = lib.mkForce false;
    services.xserver.autorun = false;
    #services.xserver.displayManager.startx.enable = true;
    #services.displayManager.sddm.enable = lib.mkForce false;
    services.upower.enable = true;
    services.tuned.enable = true;
    lun.amd-pstate.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];
    lun.ml = {
      enable = true;
      gpus = [ "amd" ];
    };
    lun.profiles = {
      server = true;
      personal = false;
      gaming = false;
      graphical = false;
    };
    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;
    my.home-manager.enabled-users = [ "lun" ];
    system.forbiddenDependenciesRegexes = [
      "kwin"
      "mutter"
    ];

    nix.settings.cores = 18;
    lun.persistence.enable = true;
    lun.persistence.dirs = [
      "/var/lib/private/atticd"
    ];
    zramSwap.enable = true;
    zramSwap.memoryPercent = 15;
    services.earlyoom.freeMemThreshold = 5;
    services.earlyoom.freeSwapThreshold = 10;
    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };
      "/boot" = {
        device = "/dev/disk/by-partlabel/_esp";
        fsType = "vfat";
        # neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = {
        device = "/dev/disk/by-partlabel/_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@persist" ] ++ btrfsSsdOpts;
      };
      "/nix" = lib.mkForce {
        device = "/dev/disk/by-partlabel/_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@nix" ] ++ btrfsSsdOpts;
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        neededForBoot = true;
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=50G" ];
      };
    };
    swapDevices = [{
      device = "/persist/swapfile.swp";
      discardPolicy = "once";
      size = 16384;
    }];
    boot.resumeDevice = if (swap != null) then swap else "";
  };
}
