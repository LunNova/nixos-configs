{ config, pkgs, lib, ... }:
let
  name = "hisame";
  swap = "/dev/disk/by-partlabel/hisame_swap_2";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" "noatime" ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "discard=async" ];
  enableFbDevs = true;
  # env = {
  #   # kwin wayland tearing support requires this for now
  #   # https://invent.kde.org/plasma/kwin/-/merge_requests/927
  #   # FIXME: remove once AMS tearing patch goes in
  #   # is already in drm-misc-next, kwin doesn't support it yet
  #   KWIN_DRM_NO_AMS = 1;
  # };
  # openrgb = pkgs.openrgb.overrideAttrs {
  #   src = pkgs.fetchFromGitLab {
  #     owner = "LunaA";
  #     repo = "OpenRGB";
  #     rev = "lunnova/pny-4090-verto";
  #     hash = "sha256-WcBJ1t5UaH9qL0hI3qtJFWFD1kROqwK0ElCRW1p60gQ=";
  #   };
  # };
  env = {
    KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "1";
    # KWIN_DRM_DEVICES = "/dev/dri/card1";
  };
  rtl_bt_fw_file = builtins.fetchurl {
    url =
      "https://github.com/Arroquw/rtl8761bu_fw/raw/refs/heads/main/rtl8761bu_fw.bin";
    sha256 = "sha256:1hdk46hly2ir4ccqcwlb48mvvpkwd3zc8vhhfhkbl770fszmn49d";
  };
  rtl8761_fw = pkgs.runCommandNoCC "rtl_bt-firmware" { } ''
    mkdir -p $out/lib/firmware/rtl_bt
    cp "${rtl_bt_fw_file}" "$out"/lib/firmware/rtl_bt/rtl8761bu_fw.bin
  '';
in
{
  config = {
    networking.hostName = "lun-${name}-nixos";
    sconfig.machineId = "63d3399d2f2f65c96848f11d73082aef";
    system.stateVersion = "22.05";

    environment.variables = env;
    environment.sessionVariables = env;

    boot.kernelParams = [
      # force fastest transfer size
      # big_root_window for rebar
      # ecrc=on to force on if not done by platform
      "pci=pcie_bus_perf,big_root_window,ecrc=on"
      "pcie_ports=native" # handle everything in linux even if uefi wants to
      "pcie_port_pm=force" # force pm on even if not wanted by platform
      "pcie_aspm=force" # force link state
      "nosplash"
      "preempt=full"

      "iommu=pt"

      # hw hwatchdog doesn't work on this platform
      "nmi_watchdog=0"
      "nowatchdog"
      "acpi_no_watchdog"

      # trust tsc, modern AMD platform
      "tsc=nowatchdog"
      # I usually turn on iommu=pt and amd_iommu=force
      # for vm performance
      # but had some instability that might be caused by it

      # List amdgpu param docs
      #   modinfo amdgpu | grep "^parm:"
      # List amdgpu param current values and undocumented params
      #   nix shell pkgs#sysfsutils -c systool -vm amdgpu
      # 10s timeout for all operations (otherwise compute defaults to 60s)
      "amdgpu.lockup_timeout=10000,10000,10000,10000"
    ];
    boot.loader.systemd-boot.consoleMode = "max";
    boot.plymouth.enable = lib.mkForce false;
    boot.kernelPatches = (lib.optionals (!enableFbDevs) [
      {
        name = "whoneedstodebuganyway";
        patch = null;
        structuredExtraConfig = with lib.kernel; {
          DRM_FBDEV_EMULATION = lib.mkForce no;
          FB_VGA16 = lib.mkForce no;
          FB_UVESA = lib.mkForce no;
          FB_VESA = lib.mkForce no;
          FB_EFI = lib.mkForce no;
          FB_NVIDIA = lib.mkForce no;
          FB_RADEON = lib.mkForce no;
        };
      }
    ]
    ) ++ [
      {
        name = "lun-cfg";
        patch = null;
        extraConfig = ''
          PCI_P2PDMA y
          DMABUF_MOVE_NOTIFY y
          HSA_AMD y
          HSA_AMD_SVM y
          HSA_AMD_P2P y
          PCI_SW_SWITCHTEC y
          FONT_TER16x32 n
        '';
      }
    ];
    boot.zswap.enable = true;

    nix.buildMachines = [
      {
        protocol = "ssh";
        system = "x86_64-linux";
        sshUser = "lun";
        hostName = "hoshitsuki-nixos.home.moonstruck.dev";
        supportedFeatures = [ "kvm" ]; # 64GB RAM
        maxJobs = 5;
        # speedFactor = 1;
      }
      {
        protocol = "ssh";
        system = "aarch64-darwin";
        sshUser = "lun";
        hostName = "luns-mbp.home.moonstruck.dev";
        supportedFeatures = [ "kvm" "big-parallel" ];
        maxJobs = 3;
        speedFactor = 2;
      }
      {
        protocol = "ssh";
        system = "aarch64-darwin";
        sshUser = "lun";
        hostName = "lun-mbp.home.moonstruck.dev";
        supportedFeatures = [ "kvm" "big-parallel" ];
        maxJobs = 2;
        speedFactor = 1;
      }
      {
        protocol = "ssh";
        system = "aarch64-linux";
        sshUser = "lun";
        hostName = "lun-aoame.home.moonstruck.dev";
        supportedFeatures = [ "big-parallel" "kvm" ]; # 64GB RAM
        maxJobs = 2;
        # speedFactor = 1;
      }
      {
        protocol = "ssh";
        system = "x86_64-linux";
        sshUser = "lun";
        hostName = "tsukikage-nixos.home.moonstruck.dev"; # 256GB RAM
        supportedFeatures = [ "big-parallel" "kvm" ];
        maxJobs = 3;
        # speedFactor = 1;
      }
      {
        protocol = "ssh";
        system = "x86_64-linux";
        sshUser = "lun";
        hostName = "tsukiakari-nixos.home.moonstruck.dev";
        supportedFeatures = [ "big-parallel" "kvm" ]; # 512GB RAM
        maxJobs = 4;
        # speedFactor = 1;
      }
    ];
    nix.settings.builders = lib.mkForce "@/etc/nix/machines";
    hardware.firmware = [ rtl8761_fw ];
    hardware.xone.enable = true;
    environment.systemPackages = [
      pkgs.lun.obsbot-camera-control
    ];

    # services.hardware.bolt.enable = true;
    services.xserver.desktopManager.plasma6.enableQt5Integration = lib.mkForce false; # FIXME: pulls in kio-extras-kf5!!
    services.desktopManager.plasma6.enable = true;
    programs.kdeconnect.enable = true;
    networking.firewall = {
      allowedTCPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
        { from = 20000; to = 65535; } # high ports
      ];
      allowedUDPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
        { from = 20000; to = 65535; } # high ports
      ];
    };
    lun.amd-pstate.enable = true;
    lun.amd-pstate.mode = "active";
    lun.conservative-governor.enable = true;
    # powerManagement.cpuFreqGovernor = "schedutil";

    lun.tablet.enable = true;
    lun.profiles = {
      personal = true;
      gaming = true;
      wineGaming = true;
    };

    services.udev.extraRules = ''
      # make mount work for ntfs devices without specifying -t ntfs3
      SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs3"
      # # remove nvidia audio
      # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
    '';

    # boot.kernelModules = [ "nct6775" "zenpower" ];
    # Use zenpower rather than k10temp for CPU temperatures.
    # boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    environment.pathsToLink = [
      "/share/wireplumber"
    ];
    boot.blacklistedKernelModules = [
      "nouveau"
      "radeon"
      # "snd_hda_intel"
      # "amdgpu"
      # "sp5100_tco" # watchdog hardware doesn't work
      # "k10temp" # replaced by zenpower
    ];
    services.upower.enable = true;
    services.tuned.enable = true;

    boot.extraModprobeConfig = ''
      options nvidia_drm modeset=1 fbdev=1
      options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_RegistryDwords=RMIntrLockingMode=1 NVreg_UsePageAttributeTable=1 NVreg_DynamicPowerManagement=0x02 NVreg_EnableGpuFirmware=0
    '';

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

    # Example with overridden source for testing 6.1
    # boot.kernelPackages =
    #   let
    #     kernel = pkgs.linux_latest.override {
    #       # stdenv = pkgs.llvmPackages_latest.stdenv; #FIXME: https://github.com/llvm/llvm-project/issues/41896
    #       argsOverride = {
    #         src = flakeArgs.linux-rc;
    #         version = "6.1.0";
    #         modDirVersion = "6.1.0";
    #         ignoreConfigErrors = true;
    #       };
    #       configfile = pkgs.linux_latest.configfile.overrideAttrs {
    #         ignoreConfigErrors = true;
    #       };
    #     };
    #   in
    #   pkgs.linuxPackagesFor kernel;

    lun.power-saving.enable = true;
    lun.efi-tools.enable = true;

    services.gvfs.enable = false;
    services.xserver.videoDrivers = [ "nvidia" ];
    services.xserver.dpi = 96; # force 100% DPI
    lun.nvidia-gpu-standalone.delayXWorkaround = true;
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production; # {production,beta} etc
    hardware.nvidia.open = false;
    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.powerManagement.enable = true;
    # lun.openxr.enable = true; FIXME ENABLE
    boot.kernelModules = [ "nvidia_uvm" ];
    systemd.services.networking.wants = [ "systemd-udev-settle.service" ];
    modules.media.audio.interfaces.scarlett2.enable = true;

    hardware.bluetooth.settings = {
      General = {
        # ControllerMode = "le";
        Experimental = true;
        KernelExperimental = "6fbaf188-05e0-496a-9885-d6ddfdb4e03e"; # BlueZ Experimental ISO socket
      };
    };
    services.pipewire = {
      enable = true;

      extraConfig.pipewire."92-latency" = {
        context.properties = {
          default.clock.quantum = 1024;
          default.clock.min-quantum = 1024;
          default.clock.max-quantum = 1024;
        };
      };

      # udev
      # Avid MBox 3 has two Analog outputs/inputs and two SPDIF Digital outputs/inputs
      # > ATTRS{idVendor}=="0dba", ATTRS{idProduct}=="5000", ENV{ACP_PROFILE_SET}="avid-mbox3.conf"
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-stop-microphone-auto-adjust.lua" ''
            table.insert (default_access.rules,{
                matches = {
                    {
                        { "application.process.binary", "=", "electron" },
                        { "application.process.binary", "=", "webcord" },
                        { "application.process.binary", "=", "firefox" },
                        { "application.process.binary", "=", "vesktop" },
                        { "application.process.binary", "=", "discord" }
                        { "application.process.binary", "=", ".Discord-wrapped" }
                    }
                },
                default_permissions = "rx",
            })
          '')
        ];
        extraConfig = {
          node.features.audio.control-port = true;
          "10-alsaUseUCM" = {
            "monitor.alsa.properties" = {
              "alsa.use-acp" = true;
              # "alsa.use-ucm" = true;
            };
          };
          "10-bluez" = {
            "monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-msbc" = true;
              "bluez5.enable-hw-volume" = true;
              "bluez5.hfphsp-backend" = "native";
              "bluez5.roles" = [
                "hsp_hs"
                "hsp_ag"
                "hfp_hf"
                "hfp_ag"
                "a2dp_sink"
                "a2dp_source"
                "bap_sink"
                "bap_source"
              ];
            };
          };
        };
      };
    };

    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;

    # debugging: sudo ip -all netns exec wg show
    lun.wg-netns = {
      enable = true;
      configFile = "/persist/mullvad/wg.env";
      isolateServices = [ "transmission" ];
      forwardPorts = [ 9091 ];
    };

    services.transmission = let downloadBase = "/persist/transmission"; in
      {
        enable = true;
        package = pkgs.transmission_4;
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
      allowedTCPPorts = [
        45982 # xmission
        22000 # syncthing (hisame stays on LAN)
      ];
      allowedUDPPorts = [
        45982 # xmission
        21027 # syncthing (hisame stays on LAN)
        22000 # syncthing (hisame stays on LAN)
      ];
    };
    nix.settings.max-jobs = 4;
    nix.settings.cores = 20;
    # FIXME: ┃ error: Unexpected exception on the Lix daemon; this is a bug in Lix.
    # ┃        We would appreciate a report of the circumstances it happened in at https://git.lix.systems/lix-project/lix.
    # ┃        nix::ForeignException: kj/async-unix.c++:466: failed: epoll_ctl(eventPort.epollFd, EPOLL_CTL_DEL, fd, nullptr): Bad file descriptor
    # ┃        stack: 7fc676fb7990 7fc67695d697 7fc676951b88 7fc676fa7f21 7fc676fa7c4e 7fc67694e730 7fc67693ebdd
    nix.settings.max-silent-time = 11111;
    boot.binfmt.emulatedSystems = lib.remove pkgs.hostPlatform.system [
      "aarch64-linux"
      "loongarch64-linux"
      "riscv64-linux"
      "x86_64-linux"
    ];
    nix.settings.extra-platforms = [
      "aarch64-linux"
      "i686-linux"
    ];

    lun.k3s = {
      enable = true;
      role = "agent";
      serverAddr = "https://hoshitsuki-nixos.home.moonstruck.dev:6443";
    };

    lun.outofdateinator.enable = true;
    lun.persistence.enable = true;
    lun.persistence.dirs = [
      "/home"
      "/var/log"
      "/nix"
      "/var/lib/transmission"
      "/var/lib/sddm"
    ];
    # services.freshrss.enable = true;
    # services.freshrss.passwordFile = "/persist/freshrss-password";
    services.miniflux.enable = true;
    services.nixseparatedebuginfod2.enable = true;
    services.miniflux.adminCredentialsFile = "/persist/miniflux-admin";
    users.users.${config.services.borgbackup.repos.uknas.user}.home = "/home/borg";
    services.borgbackup.repos = {
      uknas = {
        authorizedKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC46P3Z/EfSiZJ7xtvHWJFWDBfRH76F9EeDsqbNdTgtl1UxlmckzpCKJgZuiCq4HBQQS2D6sFHq/iVGT5mdq+SQOLZMns3gxH+wedW+XgSGScK35GV7eJjK2EASYzGWEdC/6fhARBpsMcE1cGmLckTeuRHoVGhTig/rOxXCPTPYMaTTLszPkw2D04qut4WD8IuKJegClerbyW2MV4kZdP/kIVg7gGB+jivTTtQsubgSdjw5xLS9OTK0X11f7LSpn6CqC03etnTJUe62D5j5dBLtFT55KLIDGPr86oeFnKF7/ykVSAlhmCly19eJGpG3TqZZaHrqBBtQ9iRsvgavmGiz uknas"
        ];
        path = "/mnt/_nas0/borg/uknas";
      };
    };
    # beesd will dedupe so not needed
    nix.settings.auto-optimise-store = lib.mkForce false;
    services.beesd.filesystems = {
      persist = {
        spec = "PARTLABEL=${name}_persist_2";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "1.5" ];
      };
      scratch = {
        spec = "PARTLABEL=${name}_scratch";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "1.5" ];
      };
      bigscratch = {
        spec = "PARTLABEL=${name}_bigscratch";
        hashTableSizeMB = 256;
        verbosity = "crit";
        extraOptions = [ "--loadavg-target" "1.5" ];
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
        options = [ "mode=1777" "rw" "nosuid" "nodev" "size=64G" ];
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
      { device = swap; discardPolicy = "once"; }
    ];
    boot.resumeDevice = swap;
  };
}
