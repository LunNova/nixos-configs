{ config, options, flakeArgs, lib, pkgs, ... }:
# See https://github.com/jhovold/linux/wiki/X13s for non distro specific info
let
  useGrub = false;
  inherit (config.lun.x13s) useGpu;
  useGpuFw = config.lun.x13s.useGpu;
  dtbName = "x13s66rc4.dtb";
  bindOverAlsa = true;
  remove-dupe-fw = ''
    pushd ${pkgs.linux-firmware}
    shopt -s extglob
    shopt -s globstar
    for file in */**; do
      if [ -f "$file" ] && [ -f "$out/$file" ]; then
        echo "Duplicate file $file"
        rm -fv "$out/$file"
      fi
    done
    popd
  '';
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
        NO_HZ_FULL = lib.mkForce yes;
        HZ_100 = lib.mkForce yes;
        HZ_250 = lib.mkForce no;
        DRM_AMDGPU = lib.mkForce no;
        DRM_NOUVEAU = lib.mkForce no;
      };
    }
    # {
    #   name = "x13s-hotter-revert";
    #   patch = ./x13s-hotter-revert.patch;
    # }
  ];
  linux_x13s_pkg = { buildLinux, ... } @ args:
    let
      version = "6.6.0";
      modDirVersion = "${version}-rc4";
      rev = "553fbd2f768ebcfef528ce8d42a1f082eef06d6f";
    in
    buildLinux (args // {
      inherit version modDirVersion;

      # https://github.com/steev/linux/tree/lenovo-x13s-v6.6.0-rc4
      src = pkgs.fetchFromGitHub {
        inherit rev;
        name = "x13s-linux-${modDirVersion}-${rev}";
        owner = "steev";
        repo = "linux";
        hash = "sha256-x+K7qI/f9DsgNfBdTk0kdCsR5ACQxVfpl9z21vdy43M=";
      };
      kernelPatches = (args.kernelPatches or [ ]) ++ kp;

      extraMeta.branch = "6.6";
    } // (args.argsOverride or { }));

  linux_x13s = pkgs.callPackage linux_x13s_pkg {
    defconfig = "johan_defconfig";
  };

  linuxPackages_x13s = pkgs.linuxPackagesFor linux_x13s;
  dtb = "${linuxPackages_x13s.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
  inherit (config.boot.loader) efi;

  # nurl https://github.com/kvalo/ath11k-firmware
  ath11k_fw_src = pkgs.fetchFromGitHub {
    name = "ath11k-firmware-src";
    owner = "kvalo";
    repo = "ath11k-firmware";
    rev = "5f72c2124a9b29b9393fb5e8a0f2e0abb130750f";
    hash = "sha256-l7tAxG7udr7gRHZuXRQNzWKtg5JJS+vayk44ZmisfKg=";
  };

  x13s-tplg = pkgs.fetchgit {
    name = "x13s-tplg-audioreach-topology";
    url = "https://git.linaro.org/people/srinivas.kandagatla/audioreach-topology.git";
    rev = "1ade4f466b05a86a7c7bdd51f719c08714580d14";
    hash = "sha256-GFGcm+KicTfNXSY8oMJlqBkrjdyb05C65hqK0vfCQvI=";
  };
  # nurl https://github.com/linux-surface/aarch64-firmware
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
    cp -r --no-preserve=mode,ownership ${ath11k_fw_src}/* $out/lib/firmware/ath11k/

    ${remove-dupe-fw}
  '';
  cenunix_fw_src = pkgs.fetchzip {
    url = "https://github.com/cenunix/x13s-firmware/releases/download/1.0.0/x13s-firmware.tar.gz";
    sha256 = "sha256-cr0WMKbGeJyQl5S8E7UEB/Fal6FY0tPenEpd88KFm9Q=";
    stripRoot = false;
  };
  x13s_extra_fw = pkgs.runCommandNoCC "x13s_extra_fw" { } ''
    mkdir -p $out/lib/firmware/qcom/sc8280xp/
    # mkdir -p $out/lib/firmware/qca/

    pushd "${cenunix_fw_src}"
    mkdir -p $out/lib/firmware/qcom/sc8280xp/LENOVO/21BX
    mkdir -p $out/lib/firmware/qca
    mkdir -p $out/lib/firmware/ath11k/WCN6855/hw2.0/
    # cp -v my-repo/a690_gmu.bin $out/lib/firmware/qcom
    cp -v my-repo/qcvss8280.mbn $out/lib/firmware/qcom/sc8280xp/LENOVO/21BX
    # cp -v my-repo/SC8280XP-LENOVO-X13S-tplg.bin $out/lib/firmware/qcom/sc8280xp
    cp -v my-repo/hpnv21.8c $out/lib/firmware/qca/hpnv21.b8c
    # cp -v my-repo/board-2.bin $out/lib/firmware/ath11k/WCN6855/hw2.0
    popd

    cp ${x13s-tplg}/prebuilt/qcom/sc8280xp/LENOVO/21BX/audioreach-tplg.bin $out/lib/firmware/qcom/sc8280xp/SC8280XP-LENOVO-X13S-tplg.bin
    cp -r --no-preserve=mode,ownership ${x13s-tplg}/prebuilt/* $out/lib/firmware/
    ${lib.optionalString useGpuFw ''
      # cp -r ${aarch64-fw}/firmware/qca/* $out/lib/firmware/qca/
      cp -r --no-preserve=mode,ownership ${aarch64-fw}/firmware/qcom/* $out/lib/firmware/qcom/
    ''}

    ${remove-dupe-fw}
  '';
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
      name = "alsa-ucm-conf-src";
      owner = "alsa-project";
      repo = "alsa-ucm-conf";
      # https://github.com/alsa-project/alsa-ucm-conf/pull/335/commits
      rev = "e8c3e7792336e9f68aa560db8ad19ba06ba786bb";
      hash = "sha256-4fIvgHIkTyGApM3uvucFPSYMMGYR5vjHOz6KQ26Kg7A=";
    };
  });
in
{
  options = {
    lun.x13s = {
      useGpu = lib.mkEnableOption "enable a690 gpu" // { default = true; };
    };
  };

  config = {
    specialisation.no-gpu.configuration = {
      lun.x13s.useGpu = false;
    };

    hardware.firmware = [
      (lib.hiPrio ath11k_fw)
      (lib.lowPrio (x13s_extra_fw // { compressFirmware = false; }))
    ];

    systemd.services.display-manager.serviceConfig.ExecStartPre = lib.mkIf bindOverAlsa [
      ''
        ${pkgs.bash}/bin/bash -c '${pkgs.mount}/bin/mount -o bind ${x13s-alsa-ucm-conf}/share/alsa/ ${pkgs.alsa-ucm-conf}/share/alsa/ || true'
      ''
    ];

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
        mesonFlags = old.mesonFlags ++ [
          "-Dgallium-vdpau=false"
          "-Dgallium-va=false"
          "-Dandroid-libbacktrace=disabled"
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
        canTouchEfiVariables = lib.mkForce false;
        efiSysMountPoint = "/boot";
      };

      supportedFilesystems = lib.mkForce [ "ext4" "btrfs" "cifs" "f2fs" "jfs" "ntfs" "vfat" "xfs" ];
      initrd.supportedFilesystems = lib.mkForce [ "ext4" "btrfs" "vfat" ];
      consoleLogLevel = 9;
      kernelModules = [
        "snd_usb_audio"
        "msm"
      ];
      kernelPackages = lib.mkForce linuxPackages_x13s;
      kernelParams = [
        "pcie_aspm.policy=powersupersave"
        # "pcie_aspm=force"
        "boot.shell_on_fail"
        "clk_ignore_unused"
        "pd_ignore_unused"
        "arm64.nopauth"
        "efi=noruntime"
        # "cma=128M"
        "nvme.noacpi=1" # fixes high power after suspend resume
        "iommu.strict=0" # fixes some issues when using USB devices eg slow wifi
        # "iommu.passthrough=0"
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
    });

    system.activationScripts.x13s-dtb = ''
      in_package="${dtb}"
      esp_tool_folder="${efi.efiSysMountPoint}/"
      in_esp="''${esp_tool_folder}${dtbName}"
      >&2 echo "Ensuring $in_esp in EFI System Partition"
      if ! ${pkgs.diffutils}/bin/cmp --silent "$in_package" "$in_esp"; then
        ls -l "$in_esp" || true
        >&2 echo "Copying $in_package -> $in_esp"
        mkdir -p "$esp_tool_folder"
        cp "$in_package" "$in_esp"
        sync
      fi
    '';
  };
}
