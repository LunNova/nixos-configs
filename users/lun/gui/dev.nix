{ pkgs, ... }:
{
  config = {
    home.packages = with pkgs; [
      nix-output-monitor
      jetbrains.clion
      jetbrains.idea-ultimate
      glxinfo
      vulkan-tools
    ];

    programs.vscode = {
      enable = true;
    };
  };
}
