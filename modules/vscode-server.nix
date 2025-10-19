{ flakeArgs, ... }:
{
  imports = [
    flakeArgs.vscode-server.nixosModules.default
  ];
  config = {
    services.vscode-server.enable = true;
  };
}
