{ pkgs, config, flakeArgs, ... }:
{
  security.pam.services.hyprlock = { };
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = flakeArgs.hyprland.packages.${pkgs.system}.hyprland; # pkgs.hyprland;
    # portalPackage = pkgs.xdg-desktop-portal-hyprland;
    portalPackage = flakeArgs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    systemd.setPath.enable = true;
  };
  environment.systemPackages = [
    pkgs.hyprpanel
    pkgs.hyprcursor
    config.programs.hyprland.package
  ];
}
