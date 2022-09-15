_:
{
  programs.tmux = {
    enable = true;
    # sensible defaults
    sensibleOnTop = true;

    # set by tmux-sensible but the config resets it
    escapeTime = 0;
    historyLimit = 10000;
    aggressiveResize = true;
    terminal = "tmux-256color";
    shortcut = "a";
    # focus-events

    baseIndex = 1;
    clock24 = true;

    extraConfig = ''
      setw -g mouse on
    '';
  };
}
