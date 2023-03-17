{ pkgs, ... }:
{
  config = {
    home.packages = with pkgs; [
      nix-output-monitor
      glxinfo
      vulkan-tools
    ] ++ lib.optionals (pkgs.system == "x86_64-linux") [
      jetbrains.clion
      jetbrains.idea-ultimate
    ];

    programs.vscode = {
      enable = true;
    };
  };
}
