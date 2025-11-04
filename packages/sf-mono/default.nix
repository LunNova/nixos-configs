{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation {
  pname = "SF-Mono";
  version = "v3.1.1";

  src = fetchFromGitHub {
    owner = "cpea2506";
    repo = "LigaSFMonoNerdFont";
    rev = "09821280cc300433f87dc0fcda648feb094f367f";
    sha256 = "sha256-nf2Bv9Y45tkWlklUzii4aYwuRgjN6NrehxUc1aAIR/A=";
  };

  installPhase = ''
    mkdir -p $out/share/fonts/opentype
    cp *.otf $out/share/fonts/opentype
  '';
}
