{ pkgs, ... }:
let
  inherit (pkgs) lib;
  resholvCfg = {
    inputs = with pkgs; [
      coreutils
      bash
      borgbackup
      findutils
      vulkan-tools
      gnugrep
      curl
      jq
    ] ++ (lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      bubblewrap
      slirp4netns
    ]));
    interpreter = "${pkgs.bash}/bin/bash";
    execer = [
      # See https://github.com/abathur/resholve/issues/77
      "cannot:${pkgs.borgbackup}/bin/borg"
    ] ++ (lib.optionals pkgs.stdenv.isLinux [
      # These are sometimes a lie because there's no support for can: + how to interpret the args
      "cannot:${pkgs.bubblewrap}/bin/bwrap" # can:
      "cannot:${pkgs.slirp4netns}/bin/slirp4netns" # can:
    ]);
    fake = {
      external = [
        "sudo"
        "idea-ultimate"
        "wine"
        "nix"
        "systemctl"
        "chattr"
        "btrfs"
      ];
    };
  };
  wrapScripts = path:
    let
      scripts = map (lib.removeSuffix ".sh") (builtins.attrNames (builtins.readDir path));
    in
    builtins.listToAttrs (map (x: lib.nameValuePair x (pkgs.resholve.writeScriptBin x resholvCfg (builtins.readFile "${path}/${x}.sh"))) scripts);

  lun-scripts-path = pkgs.symlinkJoin { name = "lun-scripts"; paths = lib.attrValues self.lun-scripts; };
  # https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/19101.patch
  mesaOverride =
    mesaPkg: (mesaPkg.overrideAttrs (_old: { }));
  self = {
    lun-scripts = wrapScripts ./lun-scripts;
    xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
    vkpeak = pkgs.callPackage ./vkpeak { };
    compositor-killer = pkgs.callPackage ./compositor-killer { };
    samrewritten = pkgs.callPackage ./samrewritten { };
    sillytavern = pkgs.callPackage ./sillytavern { };
    spawn = pkgs.callPackage ./spawn { };
    lun = pkgs.writeShellScriptBin "lun" ''
      exec "${lun-scripts-path}/bin/$1" "''${@:2}"
    '';
    mtoc = pkgs.callPackage ./mtoc { };
    obsbot-camera-control = pkgs.callPackage ./obsbot-camera-control { };
    switchtec-user = pkgs.callPackage ./switchtec-user { };
    svpflow = pkgs.callPackage ./svpflow { };
    sf-mono = pkgs.callPackage ./sf-mono { };
    sf-pro = pkgs.callPackage ./sf-pro { };
    # inherit (flakeArgs.nixpkgs-mesa-pr.legacyPackages.${pkgs.system}) mesa;
    mesa = mesaOverride pkgs.mesa;
    wally = pkgs.callPackage ./wally { };
  } //
  # These packages are x86_64-linux
  # This is mostly due to depending on pkgs.pkgsi686Linux to evaluate
  (lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    rmc = pkgs.python3Packages.callPackage ./rmc { };
    wowup = pkgs.callPackage ./wowup { };
    lutris = pkgs.lutris.override {
      extraLibraries = pkgs: with pkgs; [
        jansson
        gnutls
        openldap
        libgpg-error
        libpulseaudio
        sqlite
        libusb1
      ];
    };
    mesa-i686 = mesaOverride pkgs.pkgsi686Linux.mesa;
    inherit (pkgs) wine; # FIXME
    # wine = (flakeArgs.nix-gaming.packages.${pkgs.system}.wine-ge.overrideAttrs (old: {
    #   dontStrip = true;
    #   debug = true;
    #   patches = old.patches ++ [
    #     ./wine/fix-NtQueryInformationProcess-ProcessDebugPort-size.patch
    #     ./wine/log-NtWriteVirtualMemory.patch
    #     ./wine/log-NtProtectVirtualMemory.patch
    #   ];
    #   env.NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -w -Wno-incompatible-pointer-types";
    # })).override {
    #   supportFlags = {
    #     gettextSupport = true;
    #     fontconfigSupport = true;
    #     alsaSupport = true;
    #     openglSupport = true;
    #     vulkanSupport = true;
    #     tlsSupport = true;
    #     cupsSupport = true;
    #     dbusSupport = true;
    #     cairoSupport = true;
    #     cursesSupport = true;
    #     saneSupport = true;
    #     pulseaudioSupport = true;
    #     udevSupport = true;
    #     xineramaSupport = true;
    #     sdlSupport = true;
    #     mingwSupport = true;
    #     gtkSupport = false;
    #     gstreamerSupport = false;
    #     openalSupport = false;
    #     openclSupport = false;
    #     odbcSupport = false;
    #     netapiSupport = false;
    #     vaSupport = false;
    #     pcapSupport = false;
    #     v4lSupport = false;
    #     gphoto2Support = false;
    #     krb5Support = false;
    #     ldapSupport = false;
    #     vkd3dSupport = false;
    #     embedInstallers = false;
    #     waylandSupport = true;
    #     usbSupport = true;
    #     x11Support = true;
    #   };
    # };
  });
in
self
