{ stdenv
, lib
, fetchFromGitLab
, qttools
, qtbase
, kdelibs4support
, qtx11extras
, extra-cmake-modules
, cmake
, xorg
, wlroots
, pkgconfig
, kwinft
}:

stdenv.mkDerivation rec {
  pname = "disman";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "kwinft";
    repo = pname;
    rev = "fd261a3b0c8991d1deb81e2d78e575bd96f5be60";
    sha256 = "sha256-0aysBda+VFDNC5hM+xJrVtHzRUsVn0EjwFWOtx5Z6zw=";
  };

  dontWrapQtApps = true;

  nativeBuildInputs = [ cmake pkgconfig extra-cmake-modules ];

  buildInputs = [ qttools qtbase kdelibs4support qtx11extras xorg.libxcb xorg.libXrandr kwinft.wrapland ];
}
