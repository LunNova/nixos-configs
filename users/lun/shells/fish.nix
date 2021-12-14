{ config, lib, pkgs, inputs, self, ... }:
{
  # this must also be done in system
  programs.fish.enable = true;

  home.file = {
    ".config/fish/functions/fish_greeting.fish".text = ''
      function fish_greeting;end
    '';

    ".config/fish/functions/fish_prompt.fish".source = ./fish_prompt.fish;
    ".config/fish/functions/fish_right_prompt.fish".source =
      ./fish_right_prompt.fish;
    #".config/fish/conf.d/ssh-agent.fish".source = ./ssh-agent.fish;

    ".config/fish/conf.d/direnv.fish".text = ''
      direnv hook fish | source
    '';

    # global fish config
    ".config/fish/conf.d/lun.fish".text = ''
      set -gx EDITOR vim
    '';

    ".config/fish/conf.d/colors.fish".text = ''
      switch $TERM
        case '*xte*'
          set -gx TERM xterm-256color
        case '*scree*'
          set -gx TERM screen-256color
        case '*rxvt*'
          set -gx TERM rxvt-unicode-256color
      end
    '';

    ".config/fish/conf.d/gpg.fish".text = ''
      # Set GPG TTY
      set -x GPG_TTY (tty)
    '';
  };

  home.packages = [ pkgs.fishPlugins.foreign-env ];

  # programs.fish.shellAliases = {
  #   pbcopy = "${pkgs.xclip}/bin/xclip -selection clipboard";
  #   pbpaste = "${pkgs.xclip}/bin/xclip -selection clipboard -o";
  # };
}
