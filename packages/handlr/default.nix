{ lib, stdenv, rustPlatform, fetchFromGitHub, shared-mime-info, libiconv, installShellFiles }:

rustPlatform.buildRustPackage rec {
  pname = "handlr";
  version = "0.6.4-x";

  src = fetchFromGitHub {
    owner = "chmln";
    repo = pname;
    rev = "90e78ba92d0355cb523abf268858f3123fd81238";
    sha256 = "sha256-wENhlUBwfNg/r7yMKa1cQI1fbFw+qowwK8EdO912Yys=";
  };

  cargoSha256 = "sha256-EJVH7yelzKeoe/17jnc3mIGcQX7eopXhmPjnp6oicOg=";

  nativeBuildInputs = [ installShellFiles shared-mime-info ];
  buildInputs = lib.optional stdenv.isDarwin libiconv;

  preCheck = ''
    export HOME=$TEMPDIR
  '';

  postInstall = ''
    installShellCompletion \
      --zsh  completions/_handlr \
      --fish completions/handlr.fish
  '';

  meta = with lib; {
    description = "Alternative to xdg-open to manage default applications with ease";
    homepage = "https://github.com/chmln/handlr";
    license = licenses.mit;
    maintainers = with maintainers; [ mredaelli ];
  };
}
