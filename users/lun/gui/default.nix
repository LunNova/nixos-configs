{ pkgs, ... }:
{
  imports = [
    ./media
    ./cad
    ./sway
    ./conky.nix
    ./dev.nix
    ./discord.nix
    ./file-management.nix
    ./gaming.nix
    ./music.nix
    ./syncthing.nix
    ./xdg-mime-apps.nix
  ];

  config = {
    home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
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
      microsoft-edge
    ];
  };
}
