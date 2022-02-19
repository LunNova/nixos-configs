{ nixosConfig, ... }:
{
  # Modules which depend on nixosConfig being set and are otherwise not imported
  imports = if nixosConfig == null then [ ] else [
    ./input-remapper.nix
    ./blueman.nix
    ./kdeconfig.nix
  ];
}
