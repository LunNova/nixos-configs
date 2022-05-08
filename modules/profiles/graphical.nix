{ config, ... }:
{
  config = {
    # DESKTOP ENV
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    xdg.portal.gtkUsePortal = true; # Use xdg-desktop-portal for file pickers
    # services.xserver.displayManager.gdm.enable = true;
    # services.xserver.displayManager.gdm.wayland = true;
    # services.xserver.displayManager.gdm.nvidiaWayland = true;
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.desktopManager.plasma5.runUsingSystemd = true;
    # vlc is smaller than gstreamer
    services.xserver.desktopManager.plasma5.phononBackend = "vlc";

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
    services.blueman.enable = true;
    programs.dconf.enable = true;

    sconfig.yubikey = true; # modules/yubikey
  };
}
