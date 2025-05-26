{ config, lib, pkgs, ... }:
let
  inherit (lib.attrsets) getLib;

  openvrRuntimeEnv = pkgs.buildEnv {
    name = "openvr-runtime";
    paths = [
      (getLib pkgs.opencomposite)
      (getLib pkgs.xrizer)
      (lib.attrsets.getStatic pkgs.monado)
    ];
  };

  openvrRuntimeEnv32 = pkgs.buildEnv {
    name = "openvr-runtime-32bit";
    paths = [
      (getLib pkgs.pkgsi686Linux.opencomposite)
      # (lib.attrsets.getStatic pkgs.pkgsi686Linux.monado)
    ];
  };

  # wlx-overlay-s = pkgs.callPackage ({ fetchFromGitHub, rustPlatform }: rustPlatform.buildRustPackage rec {
  #   pname = "wlx-overlay-s";
  #   version = "1.2.0";

  #   src = fetchFromGitHub {
  #     owner = "galister";
  #     repo = "wlx-overlay-s";
  #     rev = "659f1492fb857e723ad5be02cbaa2828516f970f";
  #     hash = "sha256-HgLItpwVn1MU5/GKECQxJWpZFEMZkAR+BqkWx9/xay4=";
  #   };

  #   useFetchCargoVendor = true;
  #   cargoHash = "sha256-sA/8IEwVD62isx53Q15KBqNVqAT7ozWr/J0Bf63RZxE=";
  #   cargoDepsName = pname;

  #   # ...
  # }) {};
  monadoEnv = {
    LH_DEFAULT_BRIGHTNESS = "1.0";
    STEAMVR_LH_ENABLE = "1";
    XRT_COMPOSITOR_COMPUTE = "1";
    XRT_COMPOSITOR_SCALE_PERCENTAGE = "150";
    OXR_VIEWPORT_SCALE_PERCENTAGE = "125";
    WMR_HANDTRACKING = "0";
    XRT_CURATED_GUI = "1";
    IPC_EXIT_WHEN_IDLE = "1";
  };
in
{
  options.lun.openxr.enable = lib.mkEnableOption "Enable openxr compatible VR runtime with monado and opencomposite";
  config = lib.mkIf config.lun.openxr.enable {
    services.monado = {
      enable = true;
      defaultRuntime = true; # Register as default OpenXR runtime
      highPriority = true;
    };
    environment.variables = monadoEnv;
    systemd.user.services.monado.environment = monadoEnv;
    environment.systemPackages = [ pkgs.libsurvive pkgs.xrgears pkgs.wlx-overlay-s ];

    systemd.tmpfiles.settings.openvr-runtime = {
      "/run/openvr-runtime"."L+".argument = toString openvrRuntimeEnv;
      "/run/openvr-runtime-32" =
        if pkgs.stdenv.hostPlatform.isi686 then
          { "L+".argument = "openvr-runtime"; }
        else if config.hardware.graphics.enable32Bit then
          { "L+".argument = toString openvrRuntimeEnv32; }
        else
          { "r" = { }; };
    };
  };
}

