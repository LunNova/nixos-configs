{ stdenv
, lib
, cmake
, doxygen
, extra-cmake-modules
, fetchFromGitLab
, qtbase
, qttools
, wayland-protocols
, pkgconfig
, wayland
, wayland-scanner
, libinput
, egl-wayland
}:

stdenv.mkDerivation rec {
  pname = "wrapland";
  version = "1.0.0";

  dontWrapQtApps = true;

  src = fetchFromGitLab {
    owner = "kwinft";
    repo = pname;
    rev = "d075e49bf723419f7cce0f2fdd4379990bbea26b";
    sha256 = "sha256-bE/0IKYlV3iQR8WhHB5PzHAinkMZKt83hI1hE78GejQ=";
  };

  nativeBuildInputs = [ cmake doxygen extra-cmake-modules ];
  buildInputs = [ qttools qtbase wayland-protocols pkgconfig wayland wayland-scanner libinput egl-wayland ];
}
