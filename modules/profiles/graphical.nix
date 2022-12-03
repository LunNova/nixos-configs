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
      pkgs.libsForQt5.bismuth
    ];
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.desktopManager.plasma5.runUsingSystemd = true;
    # vlc is smaller than gstreamer
    services.xserver.desktopManager.plasma5.phononBackend = "vlc";

    # oom kill faster for more responsiveness
    services.earlyoom.enable = true;

    # PRINT
    lun.print.enable = true;

    # XDG
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
    };

    # GRAPHICS ACCEL
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # SOUND
    sound.enable = false;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      media-session.enable = false;
      wireplumber.enable = true;
      jack.enable = false;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      lowLatency.enable = true;
    };
    hardware.bluetooth.enable = true;

    # BLUETOOTH
    lun.persistence.dirs = [ "/var/lib/bluetooth" ];
    services.blueman.enable = true;
    programs.dconf.enable = true;

    sconfig.yubikey = false; # modules/yubikey # FIXME pam error
  };
}
