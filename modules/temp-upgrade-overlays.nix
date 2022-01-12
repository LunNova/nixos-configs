{ pkgs, ... }: {
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        # https://github.com/NixOS/nixpkgs/pull/154698
        discord-canary = let version = "0.0.132"; in
          prev.discord-canary.overrideAttrs (prev: {
            inherit version;
            src = builtins.fetchurl {
              url = "https://dl-canary.discordapp.net/apps/linux/${version}/discord-canary-${version}.tar.gz";
              sha256 = "1jjbd9qllgcdpnfxg5alxpwl050vzg13rh17n638wha0vv4mjhyv";
            };
          });
      })
    ];
  };
}
