{ config, lib, pkgs, inputs, self, ... }:
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "lun";
  home.homeDirectory = "/home/lun";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  home.packages = with pkgs; [
    direnv
    discord
    lutris
    ark
    osu-lazer
    glxinfo
    vulkan-tools
    wineWowPackages.fonts
    wineWowPackages.staging
    (lutris.override {
      lutris-unwrapped = (lutris-unwrapped.override {
        wine = wineWowPackages.staging;
      });
    })
  ];

  services.lorri.enable = true;

  programs.git = {
    enable = true;
    userName = "Luna Nova";
    userEmail = "git@nyx.nova.fail";
    extraConfig = {
      diff.colorMoved = "zebra";
      fetch.prune = true;
      init.defaultBranch = "main";
      rebase.autostash = true;
      pull.rebase = true;
    };
  };

  programs.vscode = {
    enable = true;
  };

  xdg.configFile."kcminputrc".text = ''
    [Mouse]
    XLbInptAccelProfileFlat=true
  '';

  imports = [ ./fish.nix ];
}
