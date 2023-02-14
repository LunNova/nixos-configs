# like hlissner's dotfiles https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix
# except home manager module and probably worse

{ pkgs, pkgs-stable, lib, config, ... }:
# FIXME: make this a module
{
  home.sessionPath = [
    "${config.xdg.configHome}/emacs/bin"
  ];

  home.activation.ensureDoomEmacs = ''
    if [ ! -d "${config.xdg.configHome}/emacs" ]; then
      git clone --depth=1 --single-branch "https://github.com/doomemacs/doomemacs" "${config.xdg.configHome}/emacs" || true

      # FIXME:
      # need to manually run doom install maybe that's fine

      # FIXME:
      # haven't setup a repo for config yet / might try to make it part of this repo instead
      # even if isn't nix managed properly because want it editable inplace
      # (boops says if don't do this it will be pain)
      #git clone "todo" "${config.xdg.configHome}/doom"
    fi


    if [ ! -d "${config.xdg.configHome}/doom" ]; then
      mkdir -p "${config.xdg.configHome}/doom"

      touch "${config.xdg.configHome}/doom/.projectile"

      ln -s ~/dev/nixos-configs/doom/* "${config.xdg.configHome}/doom"
    fi
  '';

  fonts.fontconfig.enable = true; # allows font in home.packages to work

  home.packages = with pkgs; [
    # FIXME: if these are all on main fontconfig path battle.net will become incredibly slow again
    emacs-all-the-icons-fonts

    ## Emacs itself
    binutils # native-comp needs 'as', provided by this
    # 28.2 + native-comp
    ((emacsPackagesFor emacsUnstable).emacsWithPackages
      (epkgs: [ epkgs.vterm ]))

    ## Doom dependencies
    git
    (ripgrep.override { withPCRE2 = true; })
    gnutls # for TLS connectivity

    ## Optional dependencies
    fd # faster projectile indexing
    imagemagick # for image-dired
    zstd # for undo-fu-session/undo-tree compression

    ## Module dependencies
    # :checkers spell
    (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
    # :tools editorconfig
    editorconfig-core-c # per-project style config
    # :tools lookup & :lang org +roam
    sqlite
    # :lang latex & :lang org (latex previews)
    texlive.combined.scheme-medium
    # :lang beancount
    beancount
    pkgs-stable.fava # FIXME: builds fails on unstable
  ];
}
