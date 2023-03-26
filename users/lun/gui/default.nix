{ pkgs, lib, lun-profiles, ... }:
{
  imports = [
    ./i3
    ./media
    ./cad
    ./sway
    # ./conky.nix # TODO: perf issues
    ./dev.nix
    ./discord.nix
    ./file-management.nix
    ./music.nix
    ./syncthing.nix
    ./vr-gaming.nix
    ./xdg-mime-apps.nix
  ] ++ lib.optionals (lun-profiles.gaming or false) [
    ./gaming.nix
  ];

  config = {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox.overrideAttrs (old: {
        postFixup = ''
          ${old.postFixup or ""}
          wrapProgram "$out/bin/firefox" --set GTK_USE_PORTAL 1 --set MOZ_ENABLE_WAYLAND 1
        '';
      });
    };
    home.packages = with pkgs; [
      pinta # paint.net alternative
      calibre
      obsidian # note taking
    ] ++ lib.optionals (pkgs.system == "x86_64-linux") [
      microsoft-edge
    ];
  };
}
