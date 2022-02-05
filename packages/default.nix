{ system, pkgs, flake-args }:
let
  lib = pkgs.lib;
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
    patches = old.patches ++ [ ];
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts ];
  });
  xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
  wrapScripts = path:
    let
      scripts = builtins.attrNames (builtins.readDir path);
    in
    builtins.listToAttrs (map (x: lib.nameValuePair x (pkgs.writeScriptBin x (builtins.readFile "${path}/${x}"))) scripts);
  powercord = pkgs.callPackage ./powercord {
    plugins = { };
    themes = { };
  };
  lun-scripts = wrapScripts ./lun-scripts;
in
{
  inherit powercord xdg-open-with-portal;
  input-remapper = pkgs.python3Packages.callPackage ./input-remapper { };
  discord-electron-update = pkgs.callPackage ./discord-electron-update rec {
    ffmpeg = pkgs.ffmpeg-full;
    electron = pkgs.electron_15;
    src = builtins.fetchurl {
      url =
        "https://dl-canary.discordapp.net/apps/linux/${version}/discord-canary-${version}.tar.gz";
      sha256 = "1jjbd9qllgcdpnfxg5alxpwl050vzg13rh17n638wha0vv4mjhyv";
    };
    version = "0.0.132";
    pname = "discord-canary";
    binaryName = "DiscordCanary";
    desktopName = "Discord Canary";
    meta = with pkgs.lib; {
      description = "All-in-one cross-platform voice and text chat for gamers";
      homepage = "https://discordapp.com/";
      downloadPage = "https://discordapp.com/download";
      license = licenses.unfree;
      maintainers = with maintainers; [ ldesgoui MP2E devins2518 ];
      platforms = [ "x86_64-linux" "x86_64-darwin" ];
    };
  };
  discord-plugged = pkgs.callPackage ./discord-plugged {
    inherit powercord;
    powercord-overlay = flake-args.powercord-overlay;
    discord-canary = pkgs.lun.discord-electron-update;
  };
  kwinft = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./kwinft { });
  lutris = pkgs.lutris.override {
    inherit lutris-unwrapped;
    extraLibraries = pkgs: [ (pkgs.hiPrio xdg-open-with-portal) ];
  };
  spawn = pkgs.callPackage ./spawn { };
  swaysome = pkgs.callPackage ./swaysome { };
  sworkstyle = pkgs.callPackage ./sworkstyle { };
  lun-scripts = lun-scripts // { all = pkgs.symlinkJoin { name = "lun-scripts"; paths = lib.attrValues lun-scripts; }; };
}
