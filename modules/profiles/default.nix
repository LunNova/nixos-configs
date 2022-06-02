{ ... }:
{
  # TODO: make these optin per host
  imports = [
    ./common.nix
    ./graphical.nix
    ./gaming.nix
    ./server.nix
    ./personal.nix
  ];
}
