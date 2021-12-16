{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
  inputs.nixpkgs-unfree-test.url = "github:lunnova/nixos-configs/nixpkgs-unfree-test";
  inputs.nixpkgs-unfree-test.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs-unfree-test, ... }:
    let lockFile = builtins.fromJSON (builtins.readFile "${nixpkgs-unfree-test}/flake.lock");
    in
    {
      test = {
        lockFile = lockFile.nodes.nixpkgs.locked.rev;
        runtime = nixpkgs-unfree-test.inputs.nixpkgs.rev;
      };
    };
}
