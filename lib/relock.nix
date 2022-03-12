lib:
let
  nixpkgs-unfree-path = ../hack-nixpkgs-unfree;


  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
in
{
  relock = {
    nixpkgs-unfree-relocked = pkgs: nixpkgs: pkgs.stdenv.mkDerivation {
      name = "nixpkgs-unfree-relocked";
      outputs = [ "out" ];
      dontUnpack = true;
      fixupPhase = "";
      installPhase = ''
        mkdir -p $out
        cp -t $out ${nixpkgs-unfree-path}/{flake.nix,flake.lock,default.nix}
        substituteInPlace $out/default.nix --replace "nixpkgs = null" 'nixpkgs = "${nixpkgs}"'
        substituteInPlace $out/flake.lock --replace \
          "%REV%" "${lock.nodes.nixpkgs.locked.rev}" --replace \
          "%HASH%" "${lock.nodes.nixpkgs.locked.narHash}"
        substituteInPlace $out/flake.nix --replace \
          "%REV%" "${lock.nodes.nixpkgs.locked.rev}"
      '';
    };
  };
}
