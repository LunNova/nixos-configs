{ nixosConfig, ... }:
{
  # Modules which depend on nixosConfig being set and are otherwise not imported
  imports = if nixosConfig == null then [ ] else
  (if nixosConfig.lun.profiles.graphical then [
    ./audio.nix
    ./input-remapper.nix
    ./blueman.nix
    ./kdeconfig.nix
  ] else [ ]);
}
