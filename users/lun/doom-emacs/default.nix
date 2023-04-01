# like hlissner's dotfiles https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix
# except home manager module and probably worse

{ pkgs, pkgs-stable, lib, config, ... }:
# FIXME: make this a module
let
  # native-comp + compile in vterm
  emacs-compiled = (pkgs.emacsPackagesFor pkgs.emacsUnstable).emacsWithPackages (epkgs: [
    epkgs.vterm
  ]);
  emacs-path = [
    pkgs.nodejs # some plugins
    pkgs.binutils # native-comp needs 'as', provided by this
    ## Doom dependencies
    pkgs.git
    (pkgs.ripgrep.override { withPCRE2 = true; })
    pkgs.gnutls # for TLS connectivity

    ## Optional dependencies
    pkgs.fd # faster projectile indexing
    pkgs.imagemagick # for image-dired
    pkgs.zstd # for undo-fu-session/undo-tree compression

    ## Module dependencies
    # :checkers spell
    (pkgs.aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
    # :tools editorconfig
    pkgs.editorconfig-core-c # per-project style config
    # :tools lookup & :lang org +roam
    pkgs.sqlite
    # :lang latex & :lang org (latex previews)
    pkgs.texlive.combined.scheme-medium
    pkgs.luajitPackages.luacheck
    emmylua-ls
    pkgs.python3
  ];
  emacs = pkgs.writeShellScriptBin "emacs" ''
    PATH="${lib.makeBinPath emacs-path}:$PATH" exec ${emacs-compiled}/bin/emacs "$@"
  '';
  emmylua-ls-jar = builtins.fetchurl {
    name = "EmmyLua-LS-all.jar";
    url = "https://github.com/EmmyLua/EmmyLua-LanguageServer/releases/download/0.5.13/EmmyLua-LS-all.jar";
    sha256 = "sha256:1fbg5kkfkdjgm2mkwr5cf7cah2vpyz4a8na8mywb94b0is56r6al";
  };
  emmylua-ls = pkgs.writeShellScriptBin "emmylua-ls" ''
    exec ${pkgs.jre}/bin/java -XX:+UseG1GC -Xmx256m -jar "${emmylua-ls-jar}" "$@"
  '';
in
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
    emacs
    emmylua-ls
  ];
}
