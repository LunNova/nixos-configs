{ nixosConfig, ... }:
{
  # Modules which depend on nixosConfig being set and are otherwise not imported
  imports = if nixosConfig == null then [ ] else [
    ./audio.nix
    ./input-remapper.nix
    ./blueman.nix
    ./kdeconfig.nix
  ];
}
