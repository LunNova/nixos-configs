{ config, lib, pkgs, ... }:
let
  linux_x13s_pkg = { buildLinux, ... } @ args:
    buildLinux (args // rec {
      version = "6.2.0";
      modDirVersion = "6.2.0-rc6";

      src = pkgs.fetchFromGitHub {
        owner = "jhovold";
        repo = "linux";
        rev = "wip/sc8280xp-v6.2-rc6";
        hash = "sha256-pHE4GouF33caUu2bIzl+PgZqDs6wM60WjguGYvJGGew=";
      };
      kernelPatches = [ ];

      extraMeta.branch = "6.2";
    } // (args.argsOverride or { }));

  linux_x13s = pkgs.callPackage linux_x13s_pkg {
    defconfig = "johan_defconfig";
  };

  linuxPackages_x13s = pkgs.linuxPackagesFor linux_x13s;
in
{
  config = {
    # https://dumpstack.io/1675806876_thinkpad_x13s_nixos.html

    boot = {
      supportedFilesystems = lib.mkForce [ "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" ];
      loader.systemd-boot.enable = true;
      kernelPackages = linuxPackages_x13s;
      kernelParams = [
        "clk_ignore_unused"
        "pd_ignore_unused"
        "arm64.nopauth"
        "cma=128M"
        "dtb=x13s.dtb"
      ];
      initrd = {
        includeDefaultModules = false;
        availableKernelModules = [
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
        ];
      };
    };
  };
}
