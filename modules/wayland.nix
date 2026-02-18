{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.lun.profiles.graphical {
    security.pam.services.hyprlock = { };
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      systemd.setPath.enable = true;
    };
    environment.systemPackages = [
      pkgs.hyprpanel
      pkgs.hyprcursor
    ];
    # Sometimes useful to force ATK support but don't run this always
    environment.sessionVariables = lib.optionalAttrs false {
      GTK_MODULES = "gail:atk-bridge";
      OOO_FORCE_DESKTOP = "gnome";
      GNOME_ACCESSIBILITY = "1";
      QT_ACCESSIBILITY = "1";
      QT_LINUX_ACCESSIBILITY_ALWAYS_ON = "1";
    };
    programs.uwsm.waylandCompositors.hyprland.binPath = lib.mkForce "/run/wrappers/bin/Hyprland";
    programs.uwsm.waylandCompositors.hyprland.prettyName = "Hyprland";
    security.wrappers."Hyprland" = {
      setuid = false;
      permissions = "u+rx,g+rx,o+rx";
      owner = "root";
      group = "root";
      # cap_sys_nice needed for asynchronous reprojection
      capabilities = "cap_sys_nice+eip";
      source = lib.getExe' config.programs.hyprland.package "hyprland";
    };
  };
}
