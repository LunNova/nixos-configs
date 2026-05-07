{ pkgs, lib, lun-profiles, nixosConfig, ... }:
{
  imports = [
    ./dev.nix
    ./file-management.nix
    ./xdg-mime-apps.nix
    ./kitty.nix
    ./compose-key.nix
    ./agent-jail.nix
  ] ++ lib.optionals (lun-profiles.personal or false) ([
    # ./conky.nix # TODO: perf issues
    ./cad
    ./music.nix
    ./syncthing.nix
    ./discord.nix
    ./media
  ] ++ lib.optionals (nixosConfig != null) [
    ./rose-pine.nix
    ./i3
    # ./sway
    ./hyprland
  ]) ++ lib.optionals (lun-profiles.gaming or false) [
    ./gaming.nix
    ./vr-gaming.nix
  ];

  config = {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
    };

    # workaround https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };

    home.packages = [
      pkgs.lun.spawn
    ] ++
    lib.optionals ((pkgs.stdenv.hostPlatform.system == "x86_64-linux") && lun-profiles.personal or false) (with pkgs; [
      pinta # paint.net alternative
      calibre
      kdePackages.ark
    ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      google-chrome
    ]);
  };
}
