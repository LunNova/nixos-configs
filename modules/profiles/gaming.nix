{ config, ... }:
{
  config = {
    programs.steam.enable = true;
    services.input-remapper.enable = true;
  };
}
