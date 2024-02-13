{ fetchFromGitHub
, stdenv
, meson
, wayland-protocols
, wayland
, cmake
, pkg-config
, egl-wayland
, libglvnd
, ninja
}:
stdenv.mkDerivation {
  pname = "compositor-killer";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "ascent12";
    repo = "compositor-killer";
    rev = "509ceaffeaabfd7146fc7c1ce430e59f83d0b2d6";
    hash = "sha256-O9btfYAipvImZxlYGIk5iG4NueGL39cHUESvnhPA920=";
  };
  postInstall = ''
    mkdir -p $out/bin
    cp ./compositor-killer $out/bin/
  '';
  nativeBuildInputs = [ meson cmake pkg-config ninja ];
  buildInputs = [ wayland-protocols wayland libglvnd egl-wayland ];
  meta.mainPackage = "compositor-killer";
}
