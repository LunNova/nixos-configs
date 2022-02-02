{
  config.nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org/"
      "https://lun-nixos-configs.cachix.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lun-nixos-configs.cachix.org-1:4jBzwzEn7vbyrnTMz9lc5JF8fYBTIT6gWDiutrkxmDU="
    ];
  };
}
