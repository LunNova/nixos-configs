{ lib
, flatbuffers
, fetchFromGitHub
, stdenv
, rustPlatform
}:

let
  libstardustxr-rs = fetchFromGitHub {
    owner = "StardustXR";
    repo = "libstardustxr-rs";
    rev = "15fa1976c70a7c934482c240de8f7fc190aae582";
    sha256 = "sha256-SgfKS7GVEluvAysdaY40QD1ctRAAahnfslv1QmCCSss=";
  };
in
rustPlatform.buildRustPackage rec {

  pname = "stardust-xr-rs";
  version = "unstable-2022-05-28";


  src = fetchFromGitHub {
    owner = "StardustXR";
    repo = "stardust-xr-rs";
    rev = "3985d9958758e867a90431c80af68a0ad83ed01f";
    sha256 = "sha256-4Zycd7OflAgdopdVP0NxP8HUJ8DCKnT/JMq3Swr4swU=";
  };
  postPatch = ''
    ln -s ${libstardustxr-rs} ../libstardustxr-rs
    cp ${./Cargo.lock} Cargo.lock
  '';

  cargoRoot = ".";
  cargoLock = {
    lockFile = ./Cargo.lock;
  };
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    flatbuffers
  ] ++ (with rustPlatform; [ cargoSetupHook rust.cargo rust.rustc ]);


  buildInputs = [ ];

  meta = with lib; {
    mainProgram = "stardust-xr";
  };
}
