{ pkgs, flake-args }:
let
  inherit (pkgs) lib;
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
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
    ];
    interpreter = "${pkgs.bash}/bin/bash";
    execer = [
      "cannot:${pkgs.borgbackup}/bin/borg"
    ];
    fake = {
      external = [ "sudo" "idea-ultimate" ];
    };
  };
  wrapScripts = path:
    let
      scripts = map (lib.removeSuffix ".sh") (builtins.attrNames (builtins.readDir path));
    in
    builtins.listToAttrs (map (x: lib.nameValuePair x (pkgs.resholve.writeScriptBin x resholvCfg (builtins.readFile "${path}/${x}.sh"))) scripts);

  lun-scripts-path = pkgs.symlinkJoin { name = "lun-scripts"; paths = lib.attrValues self.lun-scripts; };
  self = {
    lun-scripts = wrapScripts ./lun-scripts;
    xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
    kwinft = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./kwinft { });
    lutris = pkgs.lutris.override {
      inherit lutris-unwrapped;
      extraLibraries = pkgs: [ pkgs.jansson ];
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
    mesa = (flake-args.nixpkgs-mesa-pr.legacyPackages.${pkgs.system}.mesa.override {
      # MESA_LOADER_DRIVER_OVERRIDE=zink
      galliumDrivers = [ "zink" "iris" "i915" "radeonsi" "swrast" ];
      vulkanDrivers = [ "amd" "intel" "swrast" ];
      enableGalliumNine = false;
      enableOSMesa = true;
      enableOpenCL = true;
    }).overrideAttrs (old: {
      src = pkgs.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "lun";
        repo = "mesa";
        rev = "7641e3524319dd9272be822b6e70c801496d9d92";
        sha256 = "sha256-NLuNND5dJnqVocxk7zZrCJs+WxktKeUbZQVrf/nZXaQ=";
      };
      mesonFlags = (lib.lists.remove "-Dxvmc-libs-path=${placeholder "drivers"}/lib" old.mesonFlags) ++ [
        "-D vulkan-layers=device-select,overlay"
      ];
      postInstall = old.postInstall + ''
        ln -s -t $drivers/lib/ ${pkgs.vulkan-loader}/lib/lib*
        mv -t $drivers/lib $out/lib/libVkLayer*
        for js in $drivers/share/vulkan/{im,ex}plicit_layer.d/*.json; do
          substituteInPlace "$js" --replace '"libVkLayer_' '"'"$drivers/lib/libVkLayer_"
        done
      '';
    });
  };
in
self
