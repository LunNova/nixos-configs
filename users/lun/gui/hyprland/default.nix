{ pkgs, lib, flakeArgs, ... }:
let spawn = "${pkgs.lun.spawn}/bin/spawn"; in
{
  imports = [
    ./idle.nix
    flakeArgs.hyprpanel.homeManagerModules.hyprpanel
    # flakeArgs.hyprchroma.Hypr-DarkWindow
  ];
  home.packages = [
    pkgs.rofi-wayland
    pkgs.waypaper
    pkgs.hyprpaper
    pkgs.hyprpanel
  ];
  lun.hyprland-idle = {
    enable = true;
    dimPercentage = 5;
    dimTimeout = 60;
    dpmsTimeout = 180;
    lockTimeout = 600;
    suspendTimeout = null;
    # ask hyprland to dpms on if mouse moves/keyboard is pressed
    # regardless of why DPMS is off
    mouseMoveEnablesDpms = true;
    keyPressEnablesDpms = true;
    # By default, dbus, systemd and pipewire can inhibit idle
    # Set to true to allow idling while media is playing or
    # systemd/dbus idle inhibit interfaces are in use
    ignoreDbus = false;
    ignoreSystemd = false;
    ignorePipewire = false;
  };
  # IMPORTANT: set `security.pam.services.hyprlock = {};` in SYSTEM config
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        # Configure delay where only mouse movement is needed to unlock
        # grace = 300;
        hide_cursor = true;
        no_fade_in = false;
      };
      input.accel_profile = "flat";

      background = [
        {
          path = "screenshot"; # Use screen contents as background of lock screen
          # Optionally set a BG color instead:
          # color = "rgba(17, 17, 17, 1.0)";
          # Or a path to an image
          # path = "~/lock.png"
          blur_passes = 3;
          blur_size = 3;
          # Can automate loading new images over time by calling a script
          # See https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#background
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(0, 55, 252)";
          inner_color = "rgb(50, 61, 112)";
          outer_color = "rgb(2, 7, 78)";
          outline_thickness = 5;
          placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
          shadow_passes = 2;
        }
      ];
    };
  };

  services.hyprpaper.enable = true;
  services.hyprpaper.settings = {
    ipc = "on";
    splash = false;
  };
  # systemd.user.services = {
  #   hyprpaper = {
  #     Unit = {
  #       Description = "Hyprland Wallpaper daemon";
  #       Documentation = "man:hyprpaper(1)";
  #       PartOf = "wayland-session@Hyprland.target";
  #     };
  #     Service = {
  #       Type = "simple";
  #       Restart = "always";
  #     RestartSec = "5s";
  #       ExecStart = lib.getExe pkgs.hyprpaper;
  #     };
  #     Install = { WantedBy = [ "wayland-session@Hyprland.target" ]; };
  #   };
  # };

  # home.file.".config/hyprpanel/config.json".force = true;
  # xdg.configFile."hypr/hyprpaper.ini".text = ''
  #   splash = true
  # '';
  xdg.configFile.hyprpanel.force = true;
  xdg.configFile.hyprpanel.onChange = lib.mkForce "${pkgs.hyprpanel}/bin/hyprpanel r || true";
  programs.hyprpanel = {
    enable = true;
    overwrite.enable = true;
    settings = {
      layout = {
        "bar.layouts" = {
          "0" = {
            left = [ "dashboard" "workspaces" ];
            middle = [ "media" "hypridle" "ram" "cpu" "cputemp" "storage" "battery" ];
            right = [ "bluetooth" "wifi" "volume" "systray" "notifications" "clock" "power" ];
          };
        };
      };
      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_numbered = true;
      bar.workspaces.showApplicationIcons = true;
      menus.dashboard.stats.enable_gpu = false;
      menus.dashboard.powermenu.avatar.image = builtins.toString flakeArgs.self.assets.images.crescent_moon_100x100;
      theme.bar.location = "top";
      bar.customModules.cpuTemp.sensor = "/sys/devices/virtual/thermal/thermal_zone9/hwmon9/temp1_input";

      menus.dashboard.shortcuts.left.shortcut1.command = "firefox";
      menus.dashboard.shortcuts.left.shortcut1.icon = "";
      menus.dashboard.shortcuts.left.shortcut1.tooltip = "Firefox";
      menus.dashboard.shortcuts.left.shortcut2.command = "waypaper";
      menus.dashboard.shortcuts.left.shortcut2.icon = "";
      menus.dashboard.shortcuts.left.shortcut2.tooltip = "Waypaper";
    };
  };
  wayland.windowManager.hyprland = {
    enable = true;

    # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
    package = null;
    portalPackage = null;
    # Import env vars to systemd user session so portals work
    systemd.variables = [ "--all" ];

    plugins = [
      # flakeArgs.hyprchroma.packages.${pkgs.system}.Hypr-DarkWindow
      # (pkgs.hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs {
      #   src = pkgs.fetchFromGitHub {
      #     owner = "VirtCode";
      #     repo = "hypr-dynamic-cursors";
      #     rev = "e2c32d8108960b6eaf96918485503e90a016de4b";
      #     hash = "sha256-/teXJjfdp4cZetlD7lsunettI5QB3UWeODhrrDXooOs=";
      #   };
      # })
    ];

    settings = {
      exec-once = [
        "hyprpanel"
        "waypaper --restore"
      ];
      cursor = {
        no_hardware_cursors = 0;
        enable_hyprcursor = false;
        use_cpu_buffer = true;
        default_monitor = "desc:Samsung Display Corp. 0x4189,highrr,auto,1";
        # allow_dumb_copy = false;
      };
      "debug:disable_logs" = false;
      env = [
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM=wayland,xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        # "NIXOS_OZONE_WL,1"
        # "ELECTRON_OZONE_PLATFORM_HINT,auto"
        # "SDL_VIDEODRIVER,wayland"
        # "CLUTTER_BACKEND,wayland"
      ];

      windowrulev2 = [
        "plugin:chromakey, title:(.*)(Visual Studio Code)$"
        "plugin:chromakey, class:^(.*jetbrains.*)$"
        "plugin:chromakey, class:^(discord)$"
        "plugin:chromakey, class:^(legcord)$"
        "focusonactivate 1, initialClass:firefox"
        "immediate 1, initialClass:.*"
        # "opacity 1.0 0.9, class:.*"
        "opacity 0.93 0.75, class:^([cC]ode)$"
      ];

      windowrule = [
        "allowsinput 1, xwayland:1"
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;

        border_size = 2;

        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        # Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true;
        allow_tearing = true;

        layout = "dwindle";


        snap = {
          enabled = true;
        };
      };

      # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
      master = {
        new_status = "master";
      };
      xwayland.force_zero_scaling = true;

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc = {
        # using hyprpaper for custom wallpapers
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        key_press_enables_dpms = true;
      };

      render = {
        #xp_mode = 1;
        # explicit_sync = 1;
        # explicit_sync_kms = 1;
        #direct_scanout = 1;
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;

        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;

        # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, quick"
          "border, 1, 5.39, quick"
          "windows, 1, 4.79, quick"
          "windowsIn, 1, 4.1, quick, popin 87%"
          "windowsOut, 1, 1.49, quick, popin 87%"
          "fadeIn, 1, 1.73, quick"
          "fadeOut, 1, 1.46, quick"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, quick"
          "layersIn, 1, 4, quick, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, quick"
          "fadeLayersOut, 1, 1.39, quick"
          "workspaces, 1, 1.94, quick, fade"
          "workspacesIn, 1, 1.21, quick, fade"
          "workspacesOut, 1, 1.94, quick, fade"
        ];
      };
      monitor = [
        # fallback
        ",preferred,auto,1"
        # aoame
        "desc:Samsung Display Corp. 0x4189,highrr,auto,1"
        # hisame
        "desc:LG Electronics LG ULTRAGEAR+ 405NTAB8K768,3440x1440@120.04Hz,0x0,1"
        "desc:Dell Inc. DELL S3422DWG 2RSXS63,3440x1440@119.99Hz,0x-1440,1"
        "desc:HAT Kamvas Pro 13 demoset-1,2560x1600@59.97Hz,440x1440,1"
      ];
      gestures = {
        workspace_swipe = true;
        workspace_swipe_forever = true;
        workspace_swipe_distance = 150;
        workspace_swipe_direction_lock = false;
      };
      "plugin:dynamic-cursors" = {
        enabled = true;
        enable = true;
        # hw_debug = 1;
        mode = "rotate";
        rotate = {
          length = 32;
          offset = 0.0;
        };
        hyprcursor = {
          enable = false;
          enabled = false;
        };

      };

      # See https://wiki.hyprland.org/Configuring/Keywords/
      "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier

      "$terminal" = "${spawn} kitty";
      "$fileManager" = "${spawn} dolphin";
      "$menu" = "${spawn} rofi -show drun";

      bind = [
        # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
        "$mainMod, Q, killactive"
        "$mainMod, C, exec, $terminal"
        "$mainMod, M, exec, uwsm stop"
        "$mainMod, E, exec, $fileExplorer"
        "$mainMod, V, togglefloating,"
        "$mainMod, SUPER_L, exec, $menu"
        "$mainMod SHIFT, SHIFT_L, exec, $menu"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # prtscrn
        ''$mainMod, Print, exec, hyprctl setprop active opaque 1; ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" - | ${lib.getExe pkgs.satty} -f - --fullscreen --output-filename "$HOME/sync/screenshots/$(hostname)-$(date "+%Y%m%d-%T").png"; sleep 0.2; hyprctl setprop active opaque 0''
        '', Print, exec, hyprctl setprop active opaque 1; ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" "$HOME/sync/screenshots/$(hostname)-$(date "+%Y%m%d-%T").png"; sleep 0.2; hyprctl setprop active opaque 0''
        #'', Print, exec, hyprctl setprop active opaque 1; ${lib.getExe pkgs.grimblast} copysave area "$HOME/sync/screenshots/$(hostname)-$(date "+%Y-%m-%d %T").png"; sleep 0.2; hyprctl setprop active opaque 0''

        # Toggle Group with mainMod + Z
        "$mainMod, Z, togglegroup,"
        "$mainMod SHIFT, Z, moveoutofgroup,"

        # Lock Group with mainMod + X
        "$mainMod, X, lockactivegroup, toggle"

        # Cycle through groupped windows with mainMod + TAB
        "$mainMod, Grave, changegroupactive, f"
        "$mainMod SHIFT, Grave, changegroupactive, b"

        # Move windows
        "$mainMod_SHIFT, right, movewindoworgroup, r"
        "$mainMod_SHIFT, left, movewindoworgroup, l"
        "$mainMod_SHIFT, up, movewindoworgroup, u"
        "$mainMod_SHIFT, down, movewindoworgroup, d"

        "$mainMod, Right, movewindow, r"
        "$mainMod, Left, movewindow, l"

        "$mainMod Control_L, Right, workspace, e+1"
        "$mainMod Control_L, Left, workspace, e-1"
        "$mainMod Control_L, Up, workspace, emtyn"

      ];
    };
  };
}
