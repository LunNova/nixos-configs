{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, qt6
, taglib
, gst_all_1
}:
stdenv.mkDerivation rec {
  pname = "mtoc";
  version = "2.6";
  src = fetchFromGitHub {
    owner = "asa-degroff";
    repo = "mtoc";
    rev = "d076c9c83d74441722e64771084d35691accfb84";
    hash = "sha256-TAmv5oa/3Kp8ehYGYV1j2WVg0I59/tN60n8+sUZeoco=";
  };
  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qtshadertools
    taglib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];
  meta = with lib; {
    description = "Visual music player and library browser for Linux";
    homepage = "https://github.com/asa-degroff/mtoc";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "mtoc_app";
  };
}
