{ config, pkgs, lib, ... }:
{
  options.lun.profiles.graphical = (lib.mkEnableOption "Enable graphical profile") // { default = true; };
  config = lib.mkIf config.lun.profiles.graphical {
    # DESKTOP ENV
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    programs.ssh.askPassword = "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";
    # services.displayManager.sddm.wayland.enable = lib.mkDefault true;
    # services.displayManager.gdm.enable = true;
    # services.displayManager.gdm.wayland = true;
    # services.displayManager.gdm.nvidiaWayland = true;
    environment.systemPackages = lib.mkMerge [
      (lib.mkIf config.services.xserver.desktopManager.plasma5.enable [
        pkgs.libsForQt5.sddm-kcm # KDE settings panel for sddm
        pkgs.libsForQt5.bismuth # KDE tiling plugin
      ]
      )
      [
        pkgs.kdePackages.kate
        pkgs.kdePackages.kamera
      ]
      config.xdg.portal.configPackages
      config.xdg.portal.extraPortals
    ];
    services.desktopManager.plasma6.enable = true;
    services.xserver.desktopManager.plasma5.enable = false;
    services.xserver.desktopManager.plasma5.runUsingSystemd = true;
    # vlc is smaller than gstreamer
    services.xserver.desktopManager.plasma5.phononBackend = "vlc";
    services.xserver.windowManager.i3.enable = true;
    services.xserver.windowManager.i3.extraSessionCommands = ''
      systemctl --user import-environment PATH
    '';
    services.displayManager.defaultSession = "none+i3";

    # oom kill faster for more responsiveness
    services.earlyoom.enable = true;
    services.earlyoom.freeMemThreshold = 6; # defaults to 10% which is excessive
    services.earlyoom.freeSwapThreshold = 6;

    # PRINT
    # lun.print.enable = true; # FIXME: cups never works right with long uptime / after nixos-rebuild ?

    # XDG
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config.${"none+i3"}.default = [ "kde" "gtk" "gnome" "wlr" "cosmic" "*" ];
      config.hyprland.default = [ "hyprland" "kde" "gtk" "gnome" "wlr" "cosmic" "*" ];
      config.Hyprland.default = [ "hyprland" "kde" "gtk" "gnome" "wlr" "cosmic" "*" ];
    };

    # GRAPHICS ACCEL
    hardware.graphics = {
      enable = true;
      enable32Bit = lib.mkForce (pkgs.system == "x86_64-linux");
    };

    # SOUND
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      wireplumber.enable = true;
      jack.enable = false;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    hardware.bluetooth.enable = true;

    # BLUETOOTH
    lun.persistence.dirs = [ "/var/lib/bluetooth" ];
    services.blueman.enable = true;
    programs.dconf.enable = true;

    sconfig.yubikey = false; # modules/yubikey # FIXME pam error
  };
}
