{ pkgs, flake-args }:
let
  inherit (pkgs) lib;
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "lutris";
      repo = "lutris";
      rev = "e6efe2366df2c487455e0f8c429aa3dda9689ba9";
      hash = "sha256-YVm2EFWLZ7jQ2mx6VQdFX1DGAHs+mndsl2Y4JLH3Ebk=";
    };
    patches = (old.patches or [ ]) ++ [ ./lutris/more-vulkan-search-paths.patch ];
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts pkgs.python3Packages.pypresence ];
  });
  resholvCfg = {
    inputs = with pkgs; [
      coreutils
      bash
      borgbackup
      findutils
      optipng
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
      external = [ "sudo" "idea-ultimate" "wine" "nix" ];
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
    mesaPkg: ((mesaPkg.override {
      # libdrm = (if mesaPkg == pkgs.pkgsi686Linux.mesa then pkgs.pkgsi686Linux else pkgs).libdrm.overrideAttrs (old: {
      #   patches = (old.patches or [ ]) ++ [ ./mesa/libdrm-stat-workaround.patch ];
      # });
      galliumDrivers = [ "iris" "i915" "radeonsi" ];
      vulkanDrivers = [ "amd" "intel" ];
      enableGalliumNine = false;
      enableOSMesa = false;
      enableOpenCL = false;
    }).overrideAttrs (old: {
      # version = "23.0.0-dev";
      # src = pkgs.fetchFromGitLab {
      #   domain = "gitlab.freedesktop.org";
      #   owner = "mesa";
      #   repo = "mesa";
      #   rev = "321dc93276408300eefc89b5e38676582599585a";
      #   hash = "sha256-LRlF+bImSPO07AOeZKErVUNeKfHQ26oRCjQFumozT5E=";
      # };
      # mesonFlags = lib.lists.remove "-Dxvmc-libs-path=${placeholder "drivers"}/lib" old.mesonFlags;
      patches = (old.patches or [ ]) ++ [
        ./mesa/mr-19101-prereq-22.0.patch # if < 23
        ./mesa/mr-19101-device-select.patch
      ];
    }));
  mesaOverride23WithZink = mesaPkg: (mesaPkg.override {
    # MESA_LOADER_DRIVER_OVERRIDE=zink
    galliumDrivers = [ "zink" "iris" "i915" "radeonsi" "swrast" ];
    vulkanDrivers = [ "amd" "intel" "swrast" ];
    enableGalliumNine = false;
    enableOSMesa = true;
    enableOpenCL = true;
  }).overrideAttrs (old: {
    patches = old.patches ++ [ ./mesa/mr-19101-device-select.patch ];
    version = "23.0.0-dev";
    src = pkgs.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "lun";
      repo = "mesa";
      rev = "7641e3524319dd9272be822b6e70c801496d9d92";
      sha256 = "sha256-NLuNND5dJnqVocxk7zZrCJs+WxktKeUbZQVrf/nZXaQ=";
    };
    mesonFlags = lib.lists.remove "-Dxvmc-libs-path=${placeholder "drivers"}/lib" old.mesonFlags;
  });
  self = {
    lun-scripts = wrapScripts ./lun-scripts;
    xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
    kwinft = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./kwinft { });
    spawn = pkgs.callPackage ./spawn { };
    swaysome = pkgs.callPackage ./swaysome { };
    sworkstyle = pkgs.callPackage ./sworkstyle { };
    edk2-uefi-shell = pkgs.callPackage ./edk2-uefi-shell { };
    lun = pkgs.writeShellScriptBin "lun" ''
      exec "${lun-scripts-path}/bin/$1" "''${@:2}"
    '';
    svpflow = pkgs.callPackage ./svpflow { };
    # inherit (flake-args.nixpkgs-mesa-pr.legacyPackages.${pkgs.system}) mesa;
    mesa = mesaOverride pkgs.mesa;
    xorgserver = pkgs.xorg.xorgserver.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [
        "--enable-config-udev"
        "--enable-config-udev-kms"
        "--disable-config-hal"
      ];
      patches = old.patches ++ [
        # Adds KMS_DEVICE env var to restrict which card xorg will use
        ./xorg/limit-kms-devices.patch
        ./xorg/prefer-highest-refresh-mode.patch
      ];
    });
  } //
  # These packages are x86_64-linux
  # This is mostly due to depending on pkgs.pkgsi686Linux to evaluate
  (lib.optionalAttrs (pkgs.system == "x86_64-linux") {
    # FIXME: this is upstreamed?
    wowup = pkgs.callPackage ./wowup { };
    memtest86plus = pkgs.callPackage ./memtest86plus { };
    lutris = pkgs.lutris.override {
      inherit lutris-unwrapped;
      extraLibraries = pkgs: with pkgs; [
        jansson
        gnutls
        openldap
        libgpg-error
        libpulseaudio
        sqlite
        libusb
      ];
    };
    mesa-i686 = mesaOverride pkgs.pkgsi686Linux.mesa;
    wine = (flake-args.nix-gaming.packages.${pkgs.system}.wine-ge.overrideAttrs (old: {
      dontStrip = true;
      debug = true;
      patches = old.patches ++ [
        ./wine/testing.patch
      ];
    })).override {
      supportFlags = {
        gettextSupport = true;
        fontconfigSupport = true;
        alsaSupport = true;
        openglSupport = true;
        vulkanSupport = true;
        tlsSupport = true;
        cupsSupport = true;
        dbusSupport = true;
        cairoSupport = true;
        cursesSupport = true;
        saneSupport = true;
        pulseaudioSupport = true;
        udevSupport = true;
        xineramaSupport = true;
        sdlSupport = true;
        mingwSupport = true;
        gtkSupport = false;
        gstreamerSupport = false;
        openalSupport = false;
        openclSupport = false;
        odbcSupport = false;
        netapiSupport = false;
        vaSupport = false;
        pcapSupport = false;
        v4lSupport = false;
        gphoto2Support = false;
        krb5Support = false;
        ldapSupport = false;
        vkd3dSupport = false;
        embedInstallers = false;
        waylandSupport = false;
        usbSupport = true;
      };
    };
  });
in
self
