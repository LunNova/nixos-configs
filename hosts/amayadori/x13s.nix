{ config, options, flakeArgs, lib, pkgs, ... }:
let
  useGrub = false;
  useGpu = true;
  useGpuFw = true;
  dtbName = "x13s63rc3.dtb";
  kp = [
    {
      name = "x13s-cfg";
      patch = null;
      extraStructuredConfig = with lib.kernel; {
        EFI_ARMSTUB_DTB_LOADER = lib.mkForce yes;
        OF_OVERLAY = lib.mkForce yes;
        BTRFS_FS = lib.mkForce yes;
        BTRFS_FS_POSIX_ACL = lib.mkForce yes;
        MEDIA_CONTROLLER = lib.mkForce yes;
        SND_USB_AUDIO_USE_MEDIA_CONTROLLER = lib.mkForce yes;
        SND_USB = lib.mkForce yes;
        SND_USB_AUDIO = lib.mkForce module;
        USB_XHCI_PCI = lib.mkForce module;
        HZ_100 = lib.mkForce yes;
        HZ_250 = lib.mkForce no;
        DRM_AMDGPU = lib.mkForce no;
        DRM_NOUVEAU = lib.mkForce no;
      };
    }
    {
      name = "throttling";
      patch = ./qcom-cpufreq-throttling.patch;
    }
  ];
  linux_x13s_pkg = { buildLinux, ... } @ args:
    buildLinux (args // {
      version = "6.3.0";
      modDirVersion = "6.3.0-rc4";

      src = pkgs.fetchFromGitHub {
        # owner = "jhovold";
        # repo = "linux";
        # rev = "wip/sc8280xp-v6.3-rc3";
        # hash = "sha256-18Vhpc4saZilFtdCFh4520n3YGAZqsLTWAxvPkSbh9w=";
        owner = "steev";
        repo = "linux";
        rev = "lenovo-x13s-v6.3-rc4";
        hash = "sha256-OM19b5o/2aoD0wmmdbi8KTR/YLuK5HoqPLXZyMrWOXA=";
      };
      kernelPatches = (args.kernelPatches or [ ]) ++ kp;

      extraMeta.branch = "6.3";
    } // (args.argsOverride or { }));

  linux_x13s = pkgs.callPackage linux_x13s_pkg {
    defconfig = "laptop_defconfig";
  };

  linuxPackages_x13s = pkgs.linuxPackagesFor linux_x13s;
  dtb = "${linuxPackages_x13s.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
  inherit (config.boot.loader) efi;

  ath11k_fw_src = pkgs.fetchFromGitHub {
    owner = "kvalo";
    repo = "ath11k-firmware";
    rev = "fa6886ff0d62e9d84e5985e01fc75da0157c2887";
    hash = "sha256-/hXU2z+urL3GjM/s9bcyB3yIK+IUtMEbrrH30pbPh84=";
  };

  x13s-tplg = pkgs.fetchurl {
    name = "x13s-tplg.bin";
    url = "https://git.linaro.org/people/srinivas.kandagatla/audioreach-topology.git/plain/prebuilt/SC8280XP-LENOVO-X13S-tplg.bin";
    hash = "sha256-2YOjLgyHOWOnXf0Rl6APou2t2EVcqrnV1l7CtRxl0TI=";
  };
  aarch64-fw = pkgs.fetchFromGitHub {
    name = "aarch64-fw-src";
    owner = "linux-surface";
    repo = "aarch64-firmware";
    rev = "9f07579ee64aba56419cfd0fbbca9f26741edc90";
    hash = "sha256-Lyav0RtoowocrhC7Q2Y72ogHhgFuFli+c/us/Mu/Ugc=";
  };
  # TODO: https://github.com/alsa-project/alsa-ucm-conf

  ath11k_fw = pkgs.runCommandNoCC "ath11k_fw" { } ''
    mkdir -p $out/lib/firmware/ath11k/
    cp -r ${ath11k_fw_src}/* $out/lib/firmware/ath11k/
  '';
  x13s_extra_fw = pkgs.runCommandNoCC "x13s_extra_fw" { } (''
    mkdir -p $out/lib/firmware/qcom/sc8280xp/
    # mkdir -p $out/lib/firmware/qca/
    cp ${x13s-tplg} $out/lib/firmware/qcom/sc8280xp/SC8280XP-LENOVO-X13S-tplg.bin
  '' + (lib.optionalString useGpuFw ''
    # cp -r ${aarch64-fw}/firmware/qca/* $out/lib/firmware/qca/
    cp -r ${aarch64-fw}/firmware/qcom/* $out/lib/firmware/qcom/
  ''));
  # see https://github.com/szclsya/x13s-alarm
  pd-mapper = (pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/pd-mapper.nix" { inherit qrtr; }).overrideAttrs (old: {
    # TODO: use newer version and fix patch
    # src = pkgs.fetchFromGitHub {
    #   owner = "andersson";
    #   repo = "pd-mapper";
    #   rev = "107104b20bccc1089ba46893e64b3bdcb98c6830";
    #   hash = "sha256-ypLS/g1FNi2vzIYkIoml2FkMM1Tc8UrRRhWaYbwpwkc=";
    # };
  });
  qrtr = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/qrtr.nix" { };
  qmic = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/qmic.nix" { };
  rmtfs = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/rmtfs.nix" { inherit qmic qrtr; };
  uncompressed-fw = pkgs.callPackage
    ({ lib, runCommand, buildEnv, firmwareFilesList }:
      runCommand "qcom-modem-uncompressed-firmware-share"
        {
          firmwareFiles = buildEnv {
            name = "qcom-modem-uncompressed-firmware";
            paths = firmwareFilesList;
            pathsToLink = [
              "/lib/firmware/rmtfs"
              "/lib/firmware/qcom"
            ];
          };
        } ''
        PS4=" $ "
        (
        set -x
        mkdir -p $out/share/
        ln -s $firmwareFiles/lib/firmware/ $out/share/uncompressed-firmware
        )
      '')
    {
      # We have to borrow the pre `apply`'d list, thus `options...definitions`.
      # This is because the firmware is compressed in `apply` on `hardware.firmware`.
      firmwareFilesList = lib.flatten options.hardware.firmware.definitions;
    };
  x13s-alsa-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs (_: {
    src = pkgs.fetchFromGitHub {
      owner = "alsa-project";
      repo = "alsa-ucm-conf";
      # https://github.com/Srinivas-Kandagatla/alsa-ucm-conf/commits/x13s-fixes
      rev = "65b44204ea88105ed77cc68224fae440d475acca";
      hash = "sha256-iNCjyUhF16aXfe+KJ+qZ1kfhKqOOjYbsf1riDME9z9Y=";
    };
  });
in
{
  config = {
    hardware.firmware = [
      (lib.hiPrio ath11k_fw)
      (lib.hiPrio (ath11k_fw // { compressFirmware = false; }))
      (lib.lowPrio (x13s_extra_fw // { compressFirmware = false; }))
    ];

    systemd.services.display-manager.serviceConfig.ExecStartPre = [
      ''
        ${pkgs.bash}/bin/bash -c '${pkgs.mount}/bin/mount -o bind ${x13s-alsa-ucm-conf}/share/alsa/ ${pkgs.alsa-ucm-conf}/share/alsa/ || true'
      ''
    ];

    # nixpkgs.overlays = [
    #   (
    #     final: prev: let alsa-lib = 
    #         prev.alsa-lib.override {
    #           alsa-ucm-conf = prev.alsa-ucm-conf.overrideAttrs (_: rec {
    #             src = pkgs.fetchFromGitHub {
    #               owner = "alsa-project";
    #               repo = "alsa-ucm-conf";
    #               rev = "f5d3c381e4471fb90601c4ecd1d3cf72874b2b27";
    #               hash = "sha256-N180GHWlw/ztiAGkwT+Nk9w503uoO0dyxpoykGZnsNM=";
    #             };
    #           });
    #         }; in {
    #       pipewire = prev.pipewire.override {
    #         inherit alsa-lib;
    #       };
    #       alsa-utils = prev.alsa-utils.override {
    #         inherit alsa-lib;
    #       };
    #     }
    #   )
    # ];

    environment.systemPackages = [ qrtr qmic rmtfs pd-mapper uncompressed-fw ];
    environment.pathsToLink = [ "share/uncompressed-firmware" ];

    hardware.opengl.package = lib.mkIf useGpu
      ((pkgs.mesa.override {
        galliumDrivers = [ "swrast" "freedreno" "zink" ];
        vulkanDrivers = [ "swrast" "freedreno" ];
        enableGalliumNine = false;
        enableOSMesa = false;
        enableOpenCL = false;
      }).overrideAttrs (old: {
        version = "22.3.1-unstable";
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "mesa";
          repo = "mesa";
          rev = "772cacff32b2ed22799a1dbaeac6857824400f53";
          hash = "sha256-wiZXS2AmpQNn5Nl/Ai88z9leSAM70OUJCT0d0Rnd6RI=";
        };
        buildInputs = old.buildInputs ++ [
          pkgs.libunwind
          pkgs.lm_sensors
        ];
        mesonFlags = old.mesonFlags ++ [
          "-Dgallium-vdpau=false"
          "-Dgallium-va=false"
          "-Dandroid-libbacktrace=disabled"
        ];
        postPatch = old.postPatch + ''

        echo "option(
  'disk-cache-key',
  type : 'string',
  value : ${"''"},
  description : 'Mesa cache key.'
)" >> meson_options.txt 
      '';
        patches = [
          ./mesa.patch
        ];
      })).drivers;
    services.logind.extraConfig = ''
      HandlePowerKey=suspend
      HandleLidSwitch=lock
      HandleLidSwitchExternalPower=ignore
      HandleLidSwitchDocked=ignore
      IdleAction=ignore
    '';
    systemd.services = {
      # rmtfs = {
      #   wantedBy = [ "multi-user.target" ];
      #   requires = [ "qrtr-ns.service" ];
      #   after = [ "qrtr-ns.service" ];
      #   serviceConfig = {
      #     # https://github.com/andersson/rmtfs/blob/7a5ae7e0a57be3e09e0256b51b9075ee6b860322/rmtfs.c#L507-L541
      #     ExecStart = "${pkgs.rmtfs}/bin/rmtfs -s -r ${if rmtfsReadsPartition then "-P" else "-o /run/current-system/sw/share/uncompressed-firmware/rmtfs"}";
      #     Restart = "always";
      #     RestartSec = "1";
      #   };
      # };
      qrtr-ns = {
        serviceConfig = {
          ExecStart = "${qrtr}/bin/qrtr-ns -f 1";
          Restart = "always";
        };
      };
      pd-mapper = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "qrtr-ns.service" ];
        after = [ "qrtr-ns.service" ];
        serviceConfig = {
          ExecStart = "${pd-mapper}/bin/pd-mapper";
          Restart = "always";
        };
      };
    };


    # https://dumpstack.io/1675806876_thinkpad_x13s_nixos.html
    boot = {
      loader.efi = {
        canTouchEfiVariables = lib.mkForce true;
        efiSysMountPoint = "/boot";
      };

      supportedFilesystems = lib.mkForce [ "ext4" "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" ];
      consoleLogLevel = 9;
      kernelModules = [
        "snd_usb_audio"
      ];
      kernelPackages = lib.mkForce linuxPackages_x13s;
      kernelParams = [
        "boot.shell_on_fail"
        "clk_ignore_unused"
        "pd_ignore_unused"
        "arm64.nopauth"
        "cma=128M"
        "nvme.noacpi=1" # fixes high power after suspend resume
      ] ++ lib.optionals (!useGrub) [
        "dtb=${dtbName}"
      ];
      initrd = {
        includeDefaultModules = false;
        kernelModules = [
          "i2c_hid"
          "i2c_hid_of"
          "i2c_qcom_geni"
          "leds_qcom_lpg"
          "pwm_bl"
          "qrtr"
          "pmic_glink_altmode"
          "gpio_sbu_mux"
          "phy_qcom_qmp_combo"
          "panel-edp"
          "msm"
          "phy_qcom_edp"
          "i2c-core"
          "i2c-hid"
          "i2c-hid-of"
          "i2c-qcom-geni"
          "pcie-qcom"
          "phy-qcom-qmp-combo"
          "phy-qcom-qmp-pcie"
          "phy-qcom-qmp-usb"
          "phy-qcom-snps-femto-v2"
          "phy-qcom-usb-hs"
          "nvme"
        ];
      };
    } // (if useGrub then {
      loader.grub.enable = true;
      loader.grub.device = "nodev";
      loader.grub.version = 2;
      loader.grub.efiSupport = true;
      loader.systemd-boot.enable = lib.mkForce false;
    } else {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.extraFiles = {
        "${dtbName}" = dtb;
      };
    });

    #    isoImage.contents = [
    #      {
    #        source = dtb;
    #        target = "/x13s.dtb";
    #      }
    #    ];

    system.activationScripts.x13s-dtb = ''
      in_package="${dtb}"
      esp_tool_folder="${efi.efiSysMountPoint}/"
      in_esp="''${esp_tool_folder}${dtbName}"
      >&2 echo "Ensuring $in_esp in EFI System Partition"
      if ! ${pkgs.diffutils}/bin/cmp --silent "$in_package" "$in_esp"; then
        >&2 echo "Copying $in_package -> $in_esp"
        mkdir -p "$esp_tool_folder"
        cp "$in_package" "$in_esp"
        sync
      fi
    '';
  };
}
