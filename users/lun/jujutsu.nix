{ config, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      # Config reference
      # https://andre.arko.net/2025/10/15/jj-part-4-configuration/
      # consider user.name/email unset to encourage setting them per-repo?
      user.name = config.programs.git.settings.user.name;
      user.email = config.programs.git.settings.user.email;
      git.colocate = true;

      signing = {
        behavior = "own";
        backend = "ssh";
        key = config.programs.git.settings.user.signingkey;
      };

      colors = {
        commit_id = "magenta";
        change_id = "cyan";
        "working_copy empty" = "green";
        "working_copy placeholder" = "red";
        "working_copy description placeholder" = "yellow";
        "working_copy empty description placeholder" = "green";
        prefix = {
          bold = true;
          fg = "cyan";
        };
        rest = {
          bold = false;
          fg = "bright black";
        };
        "node elided" = "yellow";
        "node working_copy" = "green";
        "node conflict" = "red";
        "node immutable" = "red";
        "node normal" = { bold = false; };
        "node" = { bold = false; };
      };
      git = {
        sign-on-push = true;
        write-change-id-header = true;
      };
      aliases = {
        d = [ "diff" ];
        l = [ "log" ];
        ll = [ "log" "-r" ".." ];
        tug = [ "bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-" ];
      };
      revsets = {
        log = "current_work";
      };
      revset-aliases = {
        "stack()" = "ancestors(reachable(@, mutable()), 2)";
        "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
        "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
        "current_work" = "trunk()..@ | @..trunk() | trunk() | @:: | fork_point(trunk() | @)";
      };
      template-aliases = {
        "abbreviate_timestamp_suffix(s, suffix, abbr)" = ''
          if(
              s.ends_with(suffix),
              s.remove_suffix(suffix) ++ label("timestamp", abbr)
          )
        '';
        "abbreviate_relative_timestamp(s)" = ''
          coalesce(
              abbreviate_timestamp_suffix(s, " millisecond", "ms"),
              abbreviate_timestamp_suffix(s, " second", "s"),
              abbreviate_timestamp_suffix(s, " minute", "m"),
              abbreviate_timestamp_suffix(s, " hour", "h"),
              abbreviate_timestamp_suffix(s, " day", "d"),
              abbreviate_timestamp_suffix(s, " week", "w"),
              abbreviate_timestamp_suffix(s, " month", "mo"),
              abbreviate_timestamp_suffix(s, " year", "y"),
              s
          )
        '';
        "format_timestamp(timestamp)" = ''
          coalesce(
              if(timestamp.after("1 minute ago"), label("timestamp", "<=1m")),
              abbreviate_relative_timestamp(timestamp.ago().remove_suffix(' ago').remove_suffix('s'))
          )
        '';
      };
      templates = {
        draft_commit_description = ''
          concat(
            coalesce(description, default_commit_description, "\n"),
            if(
              config("ui.should-sign-off").as_boolean() && !description.contains("Signed-off-by: " ++ author.name()),
              "\nSigned-off-by: " ++ author.name() ++ " <" ++ author.email() ++ ">",
            ),
            surround(
              "\nJJ: This commit contains the following changes:\n", "",
              indent("JJ:     ", diff.stat(72)),
            ),
            "\nJJ: ignore-rest\n",
            diff.git(),
          )
        '';
      };
    };
  };
}
