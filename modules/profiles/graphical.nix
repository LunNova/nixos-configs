{ config, pkgs, lib, ... }:
{
  options.lun.profiles.graphical = (lib.mkEnableOption "Enable graphical profile") // { default = true; };
  config = lib.mkIf config.lun.profiles.graphical {
    # DESKTOP ENV
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    # services.xserver.displayManager.gdm.enable = true;
    # services.xserver.displayManager.gdm.wayland = true;
    # services.xserver.displayManager.gdm.nvidiaWayland = true;
    environment.systemPackages = [
      pkgs.sddm-kcm # KDE settings panel for sddm
      pkgs.libsForQt5.bismuth # KDE tiling plugin
    ];
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.desktopManager.plasma5.runUsingSystemd = true;
    # vlc is smaller than gstreamer
    services.xserver.desktopManager.plasma5.phononBackend = "vlc";
    services.xserver.windowManager.i3.enable = true;
    services.xserver.windowManager.i3.extraSessionCommands = ''
      systemctl --user import-environment PATH
    '';


    # oom kill faster for more responsiveness
    services.earlyoom.enable = true;

    # PRINT
    # lun.print.enable = true; # FIXME: cups never works right with long uptime / after nixos-rebuild ?

    # XDG
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = lib.mkIf (!config.services.xserver.desktopManager.plasma5.enable) [ pkgs.xdg-desktop-portal-gtk ];
    };

    # GRAPHICS ACCEL
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = lib.mkForce (pkgs.system == "x86_64-linux");
    };

    # SOUND
    sound.enable = false;
    hardware.pulseaudio.enable = false;
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
