{ pkgs, flakeArgs, ... }:
{
  config = {
    home.packages = with pkgs; [
      nix-output-monitor
      glxinfo
      vulkan-tools
      flakeArgs.oxalica-nil.packages.${pkgs.system}.nil
      flakeArgs.deploy-rs.packages.${pkgs.system}.default
    ] ++ lib.optionals (pkgs.system == "x86_64-linux") [
      jetbrains.clion
      jetbrains.idea-ultimate
    ];

    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };
}
