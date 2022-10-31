{ pkgs, ... }:
{
  config = {
    home.packages = with pkgs; [
      nix-output-monitor
      jetbrains.clion
      jetbrains.idea-ultimate
      jetbrains.pycharm-professional
      glxinfo
      vulkan-tools
    ];

    programs.vscode = {
      enable = true;
    };
  };
}
