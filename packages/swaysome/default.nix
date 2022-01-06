{ lib, rustPlatform, fetchFromGitLab }:

rustPlatform.buildRustPackage {
  pname = "swaysome";
  version = "git";

  src = fetchFromGitLab {
    owner = "hyask";
    repo = "swaysome";
    rev = "57272671edce717e0aa414f05d7e1a3102df8064";
    sha256 = "sha256-IZyIhEslfBl/4u1t4dKyuevY5JGjkOJblcwtSskvrA4=";
  };

  cargoSha256 = "sha256-fFHb2wPMZOtq/eQgs3TSQg1J3v1iMfnOG4JH41z7c0c=";

  meta = with lib; {
    description = "This binary helps you configure sway to work a bit more like Awesome. This currently means workspaces that are name-spaced on a per-screen basis.";
    homepage = "https://crates.io/crates/swaysome";
    license = licenses.mit;
    #maintainers = with maintainers; [ ];
  };
}
