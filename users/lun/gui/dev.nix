{ pkgs, flakeArgs, ... }:
{
  config = {
    home.packages = with pkgs; [
      nix-output-monitor
      glxinfo
      vulkan-tools
      nixd
      flakeArgs.deploy-rs.packages.${pkgs.system}.default
    ] ++ lib.optionals (pkgs.system == "x86_64-linux") [
      jetbrains.idea-ultimate
      jetbrains.rust-rover
    ];

    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };
}
