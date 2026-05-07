{ pkgs, config, lib, flakeArgs, lun-profiles, ... }:
let
  sshAddDefault = pkgs.writeShellApplication {
    name = "sshAddDefault";
    text = ''
      [[ -d ~/.ssh ]] || exit 0
      if [[ -z "''${SSH_AUTH_SOCK:-}" ]]; then
        export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent
      fi
      cd ~/.ssh
      for file in id_*; do
        if ! [[ $file =~ .*\.pub$ ]]; then
          ssh-add "$file"
        fi
      done
    '';
  };
in
{
  config = {
    home.packages = with pkgs; [
      nix-output-monitor
      mesa-demos
      vulkan-tools
      nurl # nix-prefetch-url but better
    ] ++ lib.optionals lun-profiles.personal [
      flakeArgs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default

      # LSPs
      cmake-language-server
      nixd
      nil
      lua-language-server
      typescript-language-server
      yaml-language-server
      crates-lsp

      # waylandn't
      # pkgs.lun.compositor-killer # FIXME: wayland-scanner not found
      nix-diff
      rehex
      meld # graphical diff, lets you paste in pretty easily
    ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      # FIXME: these don't work well non-fsh
      # jetbrains.idea-ultimate
      # jetbrains.rust-rover
    ];

    home.activation.makeVSCodeConfigWritable =
      let
        configDirName = {
          "vscode" = "Code";
          "vscode-insiders" = "Code - Insiders";
          "vscodium" = "VSCodium";
        }.${config.programs.vscode.package.pname};
        configPath = "${config.xdg.configHome}/${configDirName}/User/settings.json";
      in
      {
        after = [ "writeBoundary" ];
        before = [ ];
        data = ''
          echo install -m 0640 "$(readlink ${configPath})" ${configPath}
          if [ -L ${configPath} ]; then
            install -m 0640 "$(readlink -m ${configPath})" ${configPath}
          fi
        '';
      };

    home.file."${config.xdg.configHome}/Code/User/settings.json".force = true;
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
      profiles.default.userSettings = {
        "workbench.colorTheme" = "Tomorrow Night Blue";
        "editor.fontFamily" = ''"SF Mono Regular", "SF Mono", SF Mono, SFMono-Regular, monospace, 'Font Awesome 6 Brands', 'Font Awesome 6 Free', Symbola, 'Last Resort High\-Efficiency', 'Last Resort High-Efficiency', mono'';
        # Add other settings as needed
      };
      profiles.default.extensions = with pkgs.vscode-extensions; [
        flakeArgs.alicorn-vscode-extension.packages.${pkgs.stdenv.hostPlatform.system}.alicorn-vscode-extension
      ];
    };

    # https://github.com/nix-community/home-manager/issues/5988
    # services.activitywatch = {
    #   enable = true;
    #   package = pkgs.aw-server-rust;
    #   watchers = {
    #     aw-watcher-afk = {
    #       package = pkgs.activitywatch;
    #       settings = {
    #         timeout = 30;
    #         poll_time = 5;
    #       };
    #     };

    #     aw-watcher-window = {
    #       package = pkgs.activitywatch;
    #       settings = {
    #         aw-watcher-window = {
    #           poll_time = 5.0;
    #           exclude_title = false;
    #         };
    #       };
    #     };
    #   };
    # };

    services.ssh-agent.enable = true;

    systemd.user.services.ssh-agent-add-keys = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit.Wants = [ "ssh-agent.service" ];
      Service.ExecStart = "${lib.getExe sshAddDefault}";
    };
  };
}
