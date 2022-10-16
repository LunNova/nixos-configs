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
      external = [ "sudo" ];
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
      # extraLibraries = pkgs: [ (pkgs.hiPrio xdg-open-with-portal) ];
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
    mesa = flake-args.nixpkgs-mesa-pr.legacyPackages.${pkgs.system}.mesa.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        #./mesa-id-fixes/01-mr11027.patch
        # ./mesa-id-fixes/02-names.patch
      ];
    });
  };
in
self
