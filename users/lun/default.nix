{ config, lib, pkgs, pkgs-stable, self, ... }:
{
  imports = [
    ./discord.nix
    ./gaming.nix
    ./syncthing.nix
    ./xdg-mime-apps.nix
    ./modern-unix.nix
    ./music.nix
    ./sway
    ./shells/default.nix
    ./on-nixos/default.nix
  ];

  # workaround https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

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
  home.stateVersion = "21.11";

  home.packages = with pkgs; [
    glxinfo
    vulkan-tools
    nixpkgs-fmt
    rnix-lsp
    ark
    unar
    p7zip
    pinta # paint.net alternative
    calibre
  ];

  programs.git = {
    enable = true;
    lfs = {
      enable = true;
    };
    userName = "Luna Nova";
    userEmail = "git@lunnova.dev";
    extraConfig = {
      checkout.defaultRemote = "origin";
      core.eol = "lf";
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZjpZ0wdmXwnVycJw8abOpspCbfWwDDm9WA8L/k9AID lun_signing_2021-12-21";
      diff.colorMoved = "zebra";
      fetch.prune = true;
      init.defaultBranch = "main";
      rebase.autostash = true;
      pull.rebase = true;
      merge.tool = "vscode";
      diff.tool = "vscode";
      mergeTool = {
        keepBackup = false;
        vscode.cmd = "code --wait --new-window $MERGED";
      };
      difftool.vscode.cmd = "code --wait --new-window --diff $LOCAL $REMOTE";
      include.path = "./local";
    };
  };

  programs.firefox = {
    enable = true;
    package = pkgs-stable.firefox-bin;
  };

  programs.vscode = {
    enable = true;
  };

  programs.nix-index.enable = true;

  # FIXME: makes firefox open blank window?
  # systemd.user.startServices = "sd-switch";

  home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
}
