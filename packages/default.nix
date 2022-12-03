{ pkgs, flake-args }:
let
  inherit (pkgs) lib;
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./lutris/more-vulkan-search-paths.patch ];
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts ];
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
      bubblewrap
      slirp4netns
    ];
    interpreter = "${pkgs.bash}/bin/bash";
    execer = [
      # See https://github.com/abathur/resholve/issues/77
      # These are sometimes a lie because there's no support for can: + how to interpret the args
      "cannot:${pkgs.bubblewrap}/bin/bwrap" # can:
      "cannot:${pkgs.slirp4netns}/bin/slirp4netns" # can:
      "cannot:${pkgs.borgbackup}/bin/borg"
    ];
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
    mesaPkg: (mesaPkg.overrideAttrs (old: {
      patches = old.patches ++ [ ./mesa/mr-19101-device-select.patch ];
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
    spawn = pkgs.callPackage ./spawn { };
    swaysome = pkgs.callPackage ./swaysome { };
    sworkstyle = pkgs.callPackage ./sworkstyle { };
    memtest86plus = pkgs.callPackage ./memtest86plus { };
    edk2-uefi-shell = pkgs.callPackage ./edk2-uefi-shell { };
    lun = pkgs.writeShellScriptBin "lun" ''
      exec "${lun-scripts-path}/bin/$1" "''${@:2}"
    '';
    svpflow = pkgs.callPackage ./svpflow { };
    # inherit (flake-args.nixpkgs-mesa-pr.legacyPackages.${pkgs.system}) mesa;
    wowup = pkgs.callPackage ./wowup { };
    mesa = mesaOverride pkgs.mesa;
    mesa-i686 = mesaOverride pkgs.pkgsi686Linux.mesa;
    xorgserver = pkgs.xorg.xorgserver.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [
        "--enable-config-udev"
        "--enable-config-udev-kms"
        "--disable-config-hal"
      ];
      patches = old.patches ++ [
        # Adds KMS_DEVICE env var to restrict which card xorg will use
        ./xorg/limit-kms-devices.patch
      ];
    });
    wine = flake-args.nix-gaming.packages.${pkgs.system}.wine-ge.overrideAttrs (old: {
      patches = old.patches ++ [
        ./wine/testing.patch
      ];
    });
  };
in
self
