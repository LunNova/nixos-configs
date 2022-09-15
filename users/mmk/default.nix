{ pkgs, pkgs-stable, ... }:
{
  # workaround https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "mmk";
  home.homeDirectory = "/home/mmk";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    glxinfo
    vulkan-tools
    ark
    unar
    p7zip
    discord
  ];

  programs.firefox = {
    enable = true;
    package = pkgs-stable.firefox-bin;
  };

  programs.vscode = {
    enable = true;
  };
}
