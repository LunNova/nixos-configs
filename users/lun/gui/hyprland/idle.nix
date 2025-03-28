{ pkgs, config, lib, ... }:
let
  idleCfg = config.lun.hyprland-idle;
  hyprCmd = "hyprctl";
  hyprlandTargets = [
    "hyprland-session.target"
    "wayland-session.target"
    "wayland-session@Hyprland.target"
  ];
in
{
  options.lun.hyprland-idle = {
    enable = lib.mkEnableOption "Hyprland idle configuration";

    keyPressEnablesDpms = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether key presses should re-enable the display after DPMS turns it off";
    };

    mouseMoveEnablesDpms = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether mouse moves should re-enable the display after DPMS turns it off";
    };

    lockScreenCommand = lib.mkOption {
      type = lib.types.str;
      default = "loginctl lock-session";
      description = "Command to lock the screen";
    };

    dimTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 100;
      description = "Timeout in seconds before dimming the screen brightness";
    };

    dimPercentage = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Percentage to reduce brightness when dimming";
    };

    lockTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Timeout in seconds before locking the screen, null to disable";
    };

    dpmsTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 300;
      description = "Timeout in seconds before turning off the display, null to disable";
    };

    suspendTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Timeout in seconds before suspending the system, null to disable";
    };

    beforeSleepLock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to lock the screen before going to sleep";
    };

    ignorePipewire = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to ignore pipewire idle inhibitor";
    };

    ignoreDbus = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to ignore DBUS idle inhibitor";
    };

    ignoreSystemd = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to ignore systemd idle inhibitor";
    };
  };

  config = lib.mkIf idleCfg.enable {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "$mainMod, I, exec, sleep 1 && ${hyprCmd} dispatch dpms off"
      ];
      misc = lib.mkMerge [
        (lib.mkIf idleCfg.keyPressEnablesDpms {
          key_press_enables_dpms = true;
        })
        (lib.mkIf idleCfg.mouseMoveEnablesDpms {
          mouse_move_enables_dpms = true;
        })
      ];
    };

    # systemd.user.services.swayidle = {
    #   Unit.Requires = [ "graphical-session-pre.target" "wayland-session@Hyprland.target" ];
    #   Install.WantedBy = [ "wayland-session@Hyprland.target" ];;
    # };

    systemd.user.services = lib.mkMerge [
      (lib.mkIf (!idleCfg.ignorePipewire) {
        wayland-idle-pipewire-inhibit-serv = {
          Unit = {
            Wants = "graphical-session.target";
            After = "graphical-session.target";
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.wayland-pipewire-idle-inhibit}/bin/wayland-pipewire-idle-inhibit -d 5";
            Restart = "on-failure";
            RestartSec = 30;
          };

          Install.WantedBy = hyprlandTargets;
        };
      })

      # Ensure hypridle starts with Hyprland
      { hypridle.Install.WantedBy = lib.mkForce hyprlandTargets; }
    ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "${hyprCmd} dispatch dpms on";
          ignore_dbus_inhibit = idleCfg.ignoreDbus;
          lock_cmd = idleCfg.lockScreenCommand;
          ignore_systemd_inhibit = idleCfg.ignoreSystemd;
          # Add before-sleep command if enabled
          before_sleep_cmd = lib.mkIf idleCfg.beforeSleepLock idleCfg.lockScreenCommand;
        };

        listener = lib.flatten [
          # Screen dimming timeout
          (lib.optional (idleCfg.dimTimeout != null) {
            timeout = idleCfg.dimTimeout;
            on-timeout = "${lib.getExe pkgs.brightnessctl} -s set ${toString idleCfg.dimPercentage}%";
            on-resume = "${lib.getExe pkgs.brightnessctl} -r";
          })

          # Lock screen timeout
          (lib.optional (idleCfg.lockTimeout != null) {
            timeout = idleCfg.lockTimeout;
            on-timeout = idleCfg.lockScreenCommand;
          })

          # DPMS timeout
          (lib.optional (idleCfg.dpmsTimeout != null) {
            timeout = idleCfg.dpmsTimeout;
            on-timeout = "${hyprCmd} dispatch dpms off";
            on-resume = "${hyprCmd} dispatch dpms on";
          })

          # Suspend timeout
          (lib.optional (idleCfg.suspendTimeout != null) {
            timeout = idleCfg.suspendTimeout;
            on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
          })
        ];
      };
    };
  };
  #   services.swayidle = {
  #     enable = true;
  #     events = lib.mkForce (lib.flatten [
  #       (lib.optional idleCfg.beforeSleepLock {
  #         event = "before-sleep";
  #         command = idleCfg.lockScreenCommand;
  #       })
  #       { event = "after-resume"; command = "${hyprCmd} dispatch dpms on"; }
  #       { event = "unlock"; command = "${hyprCmd} dispatch dpms on"; }
  #     ]);

  #     timeouts = lib.mkForce (lib.flatten [
  #       (lib.optional (idleCfg.dimTimeout != null) {
  #         timeout = idleCfg.dimTimeout;
  #         command = "${pkgs.brillo}/bin/brillo -U ${toString idleCfg.dimPercentage}";
  #         resumeCommand = "${pkgs.brillo}/bin/brillo -A ${toString idleCfg.dimPercentage}";
  #       })
  #       (lib.optional (idleCfg.lockTimeout != null) {
  #         timeout = idleCfg.lockTimeout;
  #         command = idleCfg.lockScreenCommand;
  #       })
  #       (lib.optional (idleCfg.dpmsTimeout != null) {
  #         timeout = idleCfg.dpmsTimeout;
  #         command = "${hyprCmd} dispatch dpms off";
  #         resumeCommand = "${hyprCmd} dispatch dpms on";
  #       })
  #       (lib.optional (idleCfg.suspendTimeout != null) {
  #         timeout = idleCfg.suspendTimeout;
  #         command = "systemctl suspend";
  #       })
  #     ]);
  #   };
  # };
}
