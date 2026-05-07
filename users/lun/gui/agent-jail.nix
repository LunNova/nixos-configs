{ pkgs, lib, flakeArgs, lun-profiles, ... }:
let
  llm-agents = flakeArgs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Packages available inside the jail
  jailPath = lib.makeBinPath (with pkgs; [
    bashInteractive
    coreutils
    curl
    wget
    jq
    git
    ripgrep
    gnugrep
    gawkInteractive
    procps
    findutils
    gzip
    unzip
    gnutar
    diffutils
    python3
    perl
  ]);

  mkJailedAgent = { name, pkg, writableDirs }:
    let
      # Build --bind args for writable directories
      bindArgs = lib.concatMapStringsSep " " (dir: ''--bind "${dir}" "${dir}"'') writableDirs;
    in
    pkgs.writeShellApplication {
      name = "jailed-${name}";
      runtimeInputs = [ pkgs.bubblewrap pkgs.coreutils ];
      text = ''
        ${lib.concatMapStringsSep "\n" (dir: ''mkdir -p "${dir}"'') writableDirs}
        JAIL_DATA="$HOME/.local/share/jail-agents"
        if [ ! -e "$JAIL_DATA/passwd" ] || [ ! -e "$JAIL_DATA/group" ]; then
          mkdir -p "$JAIL_DATA"
          echo "root:x:0:0:root:/root:/bin/false" > "$JAIL_DATA/passwd"
          echo "$(id -un):x:$(id -u):$(id -g)::$HOME:/bin/false" >> "$JAIL_DATA/passwd"
          echo "root:x:0:" > "$JAIL_DATA/group"
          echo "$(id -gn):x:$(id -g):" >> "$JAIL_DATA/group"
        fi

        EXTRA_ARGS=()
        bind_path() {
          local path="$1"
          if [ -L "$path" ]; then
            local target
            target=$(realpath "$path")
            EXTRA_ARGS+=(--symlink "$target" "$path")
          elif [ -d "$path" ]; then
            # Directory: bind it directly
            EXTRA_ARGS+=(--ro-bind "$path" "$path")
          elif [ -e "$path" ]; then
            # Regular file: bind it
            EXTRA_ARGS+=(--ro-bind "$path" "$path")
          fi
        }

        bind_path /etc/hosts
        bind_path /etc/nsswitch.conf
        bind_path /etc/resolv.conf
        bind_path /etc/ssl
        bind_path /etc/localtime

        exec bwrap \
          --proc /proc \
          --dev /dev \
          --tmpfs /tmp \
          --tmpfs "$HOME" \
          --ro-bind ${pkgs.bashInteractive}/bin/bash /bin/sh \
          --symlink /bin/sh /bin/bash \
          --clearenv \
          --ro-bind "$JAIL_DATA/passwd" /etc/passwd \
          --ro-bind "$JAIL_DATA/group" /etc/group \
          --ro-bind "/usr/bin/env" /usr/bin/env \
          --ro-bind-try /run/systemd/resolve /run/systemd/resolve \
          --ro-bind /nix/store /nix/store \
          --ro-bind /etc/profiles/per-user/lun/bin /etc/profiles/per-user/lun/bin \
          --ro-bind /run/current-system/sw/bin /run/current-system/sw/bin \
          --bind "$PWD" "$PWD" \
          ${bindArgs} \
          --unshare-user --unshare-ipc --unshare-pid --unshare-uts --unshare-cgroup \
          --die-with-parent \
          --hostname jail \
          --setenv TERM "''${TERM:-xterm}" \
          --setenv PATH "${lib.getBin pkg}/bin:${jailPath}:$PATH" \
          --setenv LANG "''${LANG:-C.UTF-8}" \
          --setenv HOME "$HOME" \
          --setenv SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
          --setenv NIX_SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
          "''${EXTRA_ARGS[@]}" \
          -- bash "$@"
      '';
    };

  jailedCodex = mkJailedAgent {
    name = "codex";
    pkg = llm-agents.codex;
    writableDirs = [ "$HOME/.codex" ];
  };

  jailedOpencode = mkJailedAgent {
    name = "opencode";
    pkg = llm-agents.opencode;
    writableDirs = [ "$HOME/.config/opencode" "$HOME/.local/share/opencode" "$HOME/.local/state/opencode" ];
  };

  jailedClaudeCode = mkJailedAgent {
    name = "claude-code";
    pkg = llm-agents.claude-code;
    writableDirs = [ "$HOME/.claude" "$HOME/.config/claude-code" ];
  };
in
{
  config = lib.mkIf (lun-profiles.personal or false) {
    home.packages = [
      pkgs.code-cursor
      llm-agents.codex
      llm-agents.claude-code
      jailedCodex
      jailedOpencode
      jailedClaudeCode
    ];
  };
}
