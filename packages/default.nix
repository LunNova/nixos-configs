{ pkgs, flake-args }:
let
  inherit (pkgs) lib system;
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts ];
  });
  resholvCfg = {
    inputs = with pkgs; [ coreutils bash borgbackup ];
    interpreter = "${pkgs.bash}/bin/bash";
    execer = [
      /*
        This is the same verdict binlore will
        come up with. It's a no-op just to demo
        how to fiddle lore via the Nix API.
      */
      "cannot:${pkgs.borgbackup}/bin/borg"
    ];
  };
  wrapScripts = path:
    let
      scripts = map (lib.removeSuffix ".sh") (builtins.attrNames (builtins.readDir path));
    in
    builtins.listToAttrs (map (x: lib.nameValuePair x (pkgs.resholve.writeScriptBin x resholvCfg (builtins.readFile "${path}/${x}.sh"))) scripts);

  lun-scripts = wrapScripts ./lun-scripts;
  lun-scripts-path = pkgs.symlinkJoin { name = "lun-scripts"; paths = lib.attrValues lun-scripts; };
  self = {
    discord-plugged = pkgs.callPackage ./discord-plugged {
      inherit (self) powercord;
      inherit (flake-args) powercord-overlay;
      inherit (pkgs) discord-canary;
    };
    powercord = pkgs.callPackage ./powercord {
      plugins = { };
      themes = { };
    };
    xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
    discord-plugged-lun = self.discord-plugged.override {
      extraElectronArgs = "--ignore-gpu-blocklist --disable-features=UseOzonePlatform --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy --disable-smooth-scrolling";
      powercord = pkgs.lun.powercord.override {
        plugins = pkgs.powercord-plugins;
        themes = pkgs.powercord-themes;
      };
    };
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
  };
in
self
