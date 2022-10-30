{ config, pkgs, lib, flake-args, ... }:
let
  name = "hisame";
  swap = "/dev/disk/by-partlabel/hisame_swap";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" "noatime" "autodefrag" ];
  btrfsHddOpts = btrfsOpts ++ [ ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "discard=async" ];
  waylandEnv = {
    KMS_DEVICE = "/dev/dri/card2";
    KWIN_DRM_DEVICES = "/dev/dri/card2";
    MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE = "1";
  };
  enableFbDevs = true;
in
{
  imports = [
  ];

  config = {
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "63d3399d2f2f65c96848f11d73082aef";
    system.stateVersion = "22.05";

    boot.kernelParams = [
      # force fastest transfer size
      # big_root_window for rebar
      # ecrc=on to force on if not done by platform
      "pci=pcie_bus_perf,big_root_window,ecrc=on"
      "pcie_ports=native" # handle everything in linux even if uefi wants to
      "pcie_port_pm=force" # force pm on even if not wanted by platform
      "pcie_aspm=force" # force link state

      # Potential workaround for high idle mclk?
      # https://gitlab.freedesktop.org/drm/amd/-/issues/1301#note_629735
      # or https://gitlab.freedesktop.org/drm/amd/-/issues/1403#note_1190209
      # FIXME: investigate these options once monitor arrives
      # video="HDMI-A-1:2560x1440R@110D" - should be the mode for the 110Hz 24" 1440p Lenovo - G24qe-20
      # "video=d"
      # "video=DP-13:2560x1440R@165D"
      # #"video=DP-13:2560x1440R@144D"
      # "video=DP-14:3440x1440R@72"
      # #"video=DP-14:3440x1440R@70"
      # "video=DP-14:3440x1440R@60"

      # hw hwatchdog doesn't work on this platform
      "nmi_watchdog=0"
      "nowatchdog"
      "acpi_no_watchdog"

      # trust tsc, modern AMD platform
      "tsc=nowatchdog"
      # I usually turn on iommu=pt and amd_iommu=force
      # for vm performance
      # but had some instability that might be caused by it

      # disable first two intel hda devices
      "snd_hda_intel.enable=0,0"

      # List amdgpu param docs
      #   modinfo amdgpu | grep "^parm:"
      # List amdgpu param current values and undocumented params
      #   nix shell pkgs#sysfsutils -c systool -vm amdgpu

      # 10s timeout for all operations (otherwise compute defaults to 60s)
      "amdgpu.lockup_timeout=10000,10000,10000,10000"
      # runpm:PX runtime pm (2 = force enable with BAMACO, 1 = force enable with BACO, 0 = disable, -1 = auto) (int)
      # BAMACO = keeps memory powered up too for faster enter/exit?
      "amdgpu.runpm=2"
      "amdgpu.aspm=1"
      # "amdgpu.bapm=0"

      # sched_policy:Scheduling policy (0 = HWS (Default), 1 = HWS without over-subscription, 2 = Non-HWS (Used for debugging only) (int)
      # "amdgpu.sched_policy=2" # maybe workaround GPU driver crash with mixed graphics/compute loads
      # "amdgpu.vm_update_mode=3" # same, maybe workaround
      # "amdgpu.mcbp=1"
      #"amdgpu.ppfeaturemask=0xffffffff" # enable all powerplay features
      "amdgpu.gpu_recovery=2" # advanced TDR mode
      # reset_method:GPU reset method (-1 = auto (default), 0 = legacy, 1 = mode0, 2 = mode1, 3 = mode2, 4 = baco/bamaco) (int)
      "amdgpu.reset_method=4"

      # TODO: Move into amdgpu-no-ecc module
      "amdgpu.ras_enable=0"
    ];
    boot.plymouth.enable = lib.mkForce false;
    boot.kernelPatches = (lib.optionals (!enableFbDevs) [
      {
        name = "whoneedstodebuganyway";
        patch = null;
        extraStructuredConfig = with lib.kernel; {
          DRM_FBDEV_EMULATION = lib.mkForce no;
          FB_VGA16 = lib.mkForce no;
          FB_UVESA = lib.mkForce no;
          FB_VESA = lib.mkForce no;
          FB_EFI = lib.mkForce no;
          FB_NVIDIA = lib.mkForce no;
          FB_RADEON = lib.mkForce no;
        };
      }
    ]) ++ [
      {
        name = "amdgpu-no-ecc";
        patch = ./kernel/amdgpu-no-ecc.patch;
      }
      {
        name = "amdgpu_bo_fence_warn.patch";
        patch = ./kernel/amdgpu_bo_fence_warn.patch;
      }
      {
        name = "log-psp-resume";
        patch = ./kernel/log-psp-resume.patch;
      }
      {
        name = "amdgpu-pm-no-resume";
        patch = ./kernel/amdgpu-pm-no-resume.patch;
      }
      # {
      #   name = "amdgpu-force-d3.patch";
      #   patch = ./kernel/amdgpu-force-d3.patch;
      # }
      # {
      #   name = "disable-acs-redir.patch";
      #   patch = ./kernel/disable-acs-redir.patch;
      # }
    ];
    lun.amd-pstate.enable = true;
    lun.amd-pstate.sharedMem = true;
    boot.kernelModules = [ "cpufreq_conservative" ];
    powerManagement.cpuFreqGovernor = "conservative";

    systemd.services.displayManager.environment = waylandEnv;
    environment.variables = waylandEnv;
    environment.sessionVariables = waylandEnv;
    services.resolved.enable = true;
    services.resolved.llmnr = "true";
    system.nssDatabases.hosts = lib.mkForce [ "mymachines resolve [!UNAVAIL=return] files myhostname" ];
    services.udev.extraRules = ''
      # Remove AMD GPU Audio devices, if present
      # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{class}=="0x040300", ATTR{remove}="1"
      # This causes critical thermal fails so don't do it ^ :/

      SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs3"

      # ensure only card2 gets used as seat master
      SUBSYSTEM=="drm", KERNEL=="card[0-1]", TAG-="seat", TAG-="master-of-seat", ENV{ID_FOR_SEAT}="", ENV{ID_PATH}=""
      SUBSYSTEM=="drm", KERNEL=="card2", TAG+="seat", TAG+="master-of-seat", TAG+="mutter-device-preferred-primary"
    '';
    services.xserver.displayManager.defaultSession = "plasmawayland";
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.sddm.enable = lib.mkForce false;
    #services.xserver.displayManager.sddm.settings.General.DisplayServer = "wayland";
    #services.xserver.displayManager.sddm.settings.Wayland.CompositorCommand = "${pkgs.weston}/bin/weston --drm-device=card2 --shell=fullscreen-shell.so";


    # boot.kernelModules = [ "nct6775" "zenpower" ];
    # Use zenpower rather than k10temp for CPU temperatures.
    # boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    boot.blacklistedKernelModules = [
      "sp5100_tco" # watchdog hardware doesn't work
      # "k10temp" # replaced by zenpower
    ];
    services.power-profiles-daemon.enable = true;

    # most important change is tickless kernel
    # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    # Example with overridden source for testing 6.1
    boot.kernelPackages =
      let
        kernel = pkgs.linux_latest.override {
          argsOverride = {
            src = flake-args.linux-freedesktop-drm-misc-fixes;
            version = "6.1.0-dmf";
            modDirVersion = "6.1.0-rc2";
            ignoreConfigErrors = true;
          };
          configfile = pkgs.linux_latest.configfile.overrideAttrs {
            ignoreConfigErrors = true;
          };
        };
      in
      pkgs.linuxPackagesFor kernel;

    lun.power-saving.enable = true;
    lun.efi-tools.enable = true;

    services.xserver.videoDrivers = [ "amdgpu" ];
    lun.ml = {
      enable = true;
      gpus = [ "amd" ];
    };
    hardware.opengl = {
      package = pkgs.lun.mesa.drivers;
      extraPackages = [
        pkgs.lun.mesa.drivers
        # Seems to perform worse but may be worth trying if ever run into vulkan issues
        # pkgs.amdvlk
      ];
      extraPackages32 = [
        pkgs.pkgsi686Linux.mesa.drivers
      ];
    };

    services.plex = {
      enable = true;
      openFirewall = true;
      dataDir = "/persist/plex/";
    };
    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;

    lun.home-assistant.enable = true;
    lun.wg-netns = {
      enable = true;

      privateKey = "/persist/mullvad/priv.key";
      peerPublicKey = "ctROwSybsU4cHsnGidKtbGYWRB2R17PFMMAqEHpsSm0=";
      endpointAddr = "198.54.133.82:51820";
      ip4 = "10.65.206.162/32";
      ip6 = "fc00:bbbb:bbbb:bb01::2:cea1/128";

      isolateServices = [ "transmission" ];
      forwardPorts = [ 9091 ];

      # dns = [ "10.64.0.1" ];
    };

    services.transmission = let downloadBase = "/persist/transmission"; in
      {
        enable = true;
        # group = "nas";

        settings = {
          download-dir = "${downloadBase}/default";
          incomplete-dir = "${downloadBase}/incomplete";

          peer-port = 45982;

          rpc-enabled = true;
          rpc-port = 9091;
          rpc-authentication-required = true;

          rpc-username = "lun";
          rpc-password = "nix-placeholder";

          # Proxied behind nginx.
          rpc-whitelist-enabled = false;
          rpc-whitelist = "127.0.0.1";

          verify-threads = 4;
        };
      };
    networking.firewall = {
      allowedTCPPorts = [ 45982 ];
      allowedUDPPorts = [ 45982 ];
    };

    lun.persistence.enable = true;
    lun.persistence.dirs = [
      "/home"
      "/var/log"
      "/nix"
      "/var/lib/transmission"
    ];
    users.users.${config.services.borgbackup.repos.uknas.user}.home = "/home/borg";
    services.borgbackup.repos = {
      uknas = {
        authorizedKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC46P3Z/EfSiZJ7xtvHWJFWDBfRH76F9EeDsqbNdTgtl1UxlmckzpCKJgZuiCq4HBQQS2D6sFHq/iVGT5mdq+SQOLZMns3gxH+wedW+XgSGScK35GV7eJjK2EASYzGWEdC/6fhARBpsMcE1cGmLckTeuRHoVGhTig/rOxXCPTPYMaTTLszPkw2D04qut4WD8IuKJegClerbyW2MV4kZdP/kIVg7gGB+jivTTtQsubgSdjw5xLS9OTK0X11f7LSpn6CqC03etnTJUe62D5j5dBLtFT55KLIDGPr86oeFnKF7/ykVSAlhmCly19eJGpG3TqZZaHrqBBtQ9iRsvgavmGiz uknas"
        ];
        path = "/mnt/_nas0/borg/uknas";
      };
    };
    services.beesd.filesystems = {
      persist = {
        spec = "PARTLABEL=${name}_persist_2";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "2.0" ];
      };
      scratch = {
        spec = "PARTLABEL=${name}_scratch";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "2.0" ];
      };
    };
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
      "/boot" = lib.mkForce {
        device = "/dev/disk/by-partlabel/${name}_esp_2";
        fsType = "vfat";
        neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = lib.mkForce {
        device = "/dev/disk/by-partlabel/${name}_persist_2";
        fsType = "btrfs";
        neededForBoot = true;
        options = btrfsSsdOpts ++ [ "subvol=@persist" "nodev" "nosuid" ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        neededForBoot = true;
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=32G" ];
      };
      "/mnt/_nas0" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/_nas0";
        neededForBoot = false;
        options = btrfsHddOpts ++ [ "nofail" ];
      };
      "/mnt/scratch" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/hisame_scratch";
        neededForBoot = false;
        options = btrfsSsdOpts ++ [ "nofail" "subvol=@scratch" ];
      };
      "/mnt/bigscratch" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/hisame_bigscratch";
        neededForBoot = false;
        options = btrfsSsdOpts ++ [ "nofail" "subvol=@main" ];
      };
    };
    swapDevices = lib.mkForce [
      { device = swap; }
    ];
    boot.resumeDevice = swap;
  };
}
