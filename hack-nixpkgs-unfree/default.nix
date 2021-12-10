{ system ? builtins.currentSystem or "unknown-system", ... }:
let
  nixpkgs = null;# substituted with nixpkgs path
in
import nixpkgs {
  inherit system;
  config.allowUnfree = true;
}
