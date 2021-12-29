{ stdenv
, lib
, extra-cmake-modules
, cmake
, pkgconfig
, fetchFromGitLab
, qttools
, kwinft
, kdelibs4support
, kirigami2
, qtdeclarative
, kcmutils
, plasma-framework
, qtbase
, kdeclarative
, qtsensors
}:

stdenv.mkDerivation {
  pname = "Kdisplay";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "kwinft";
    repo = "kdisplay";
    rev = "b64cf06bf9945b550a965126c750440a6617e4ef";
    sha256 = "sha256-MXmEG0uKegjWIYCCIdSitn8+PmgCP8ETJ3uT8LFcSco=";
  };

  dontWrapQtApps = true;

  nativeBuildInputs = [ pkgconfig cmake extra-cmake-modules ];

  buildInputs = [ qttools kwinft.disman kirigami2 qtbase qtsensors kdelibs4support qtdeclarative kdeclarative kcmutils plasma-framework ];
}
