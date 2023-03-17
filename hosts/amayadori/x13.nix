{ config, options, flakeArgs, lib, pkgs, ... }:
let
  linux_x13s_pkg = { buildLinux, ... } @ args:
    buildLinux (args // rec {
      version = "6.3.0";
      modDirVersion = "6.3.0-rc2";

      src = pkgs.fetchFromGitHub {
        owner = "jhovold";
        repo = "linux";
        rev = "wip/sc8280xp-v6.3-rc2-wifi";
        hash = "sha256-b8Vhpc4saZilFtdCFh4520n3YGAZqsLTWAxvPkSbh9w=";
      };
      kernelPatches = [ ];

      extraMeta.branch = "6.3";
    } // (args.argsOverride or { }));

  linux_x13s = pkgs.callPackage linux_x13s_pkg {
    defconfig = "johan_defconfig";
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

  x13s_fw = pkgs.runCommandNoCC "ath11k_fw" { } ''
    mkdir -p $out/lib/firmware/ath11k/
    cp -r ${ath11k_fw_src}/* $out/lib/firmware/ath11k/
    mkdir -p $out/lib/firmware/qcom/sc8280xp/
    # mkdir -p $out/lib/firmware/qca/
    cp ${x13s-tplg} $out/lib/firmware/qcom/sc8280xp/SC8280XP-LENOVO-X13S-tplg.bin
    # cp -r ${aarch64-fw}/firmware/qca/* $out/lib/firmware/qca/
    cp -r ${aarch64-fw}/firmware/qcom/* $out/lib/firmware/qcom/
  '';
  # see https://github.com/szclsya/x13s-alarm
  pd-mapper = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/pd-mapper.nix" { inherit qrtr; };
  qrtr = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/qrtr.nix" { };
  qmic = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/qmic.nix" { };
  rmtfs = pkgs.callPackage "${flakeArgs.mobile-nixos}/overlay/qrtr/rmtfs.nix" { inherit qmic qrtr; };
  uncompressed-fw = pkgs.callPackage
    (
      { lib
      , runCommand
      , buildEnv
      , firmwareFilesList
      }:

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
      ''
    )
    {
      # We have to borrow the pre `apply`'d list, thus `options...definitions`.
      # This is because the firmware is compressed in `apply` on `hardware.firmware`.
      firmwareFilesList = lib.flatten options.hardware.firmware.definitions;
    };
in
{
  config = {
    hardware.firmware = [
      (lib.hiPrio x13s_fw)
      (lib.hiPrio (x13s_fw // { compressFirmware = false; }))
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
      loader.grub.enable = true;
      loader.grub.device = "nodev";
      loader.grub.version = 2;
      loader.grub.efiSupport = true;
      loader.systemd-boot.enable = lib.mkForce false;

      supportedFilesystems = lib.mkForce [ "ext4" "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" ];
      #loader.systemd-boot.enable = true;
      #loader.systemd-boot.extraFiles = {
      #  "x13s.dtb" = dtb;
      #};
      consoleLogLevel = 9;
      kernelPackages = lib.mkForce linuxPackages_x13s;
      kernelParams = [
        "boot.shell_on_fail"
        "clk_ignore_unused"
        "pd_ignore_unused"
        "arm64.nopauth"
        "cma=128M"
        #"dtb=x13s.dtb"
      ];
      kernelPatches = [
        {
          name = "x13s-cfg";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            EFI_ARMSTUB_DTB_LOADER = lib.mkForce yes;
            OF_OVERLAY = lib.mkForce yes;
            BTRFS_FS = lib.mkForce yes;
            BTRFS_FS_POSIX_ACL = lib.mkForce yes;
            # USB_XHCI_PCI = lib.mkForce module;
          };
        }
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
    };

    #    isoImage.contents = [
    #      {
    #        source = dtb;
    #        target = "/x13s.dtb";
    #      }
    #    ];

    system.activationScripts.x13s-dtb = ''
      in_package="${dtb}"
      esp_tool_folder="${efi.efiSysMountPoint}/"
      in_esp="''${esp_tool_folder}x13s.dtb"
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
