{ lib
, stdenv
, fetchFromGitHub
, cmake
, qt6
, autoPatchelfHook
}:

stdenv.mkDerivation rec {
  pname = "obsbot-camera-control";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "aaronsb";
    repo = "obsbot-camera-control";
    rev = "5c2eb7dbafa2460803f6f875410b05524e692f8d";
    hash = "sha256-QzMJVsIwwRwTv3sVhQGdqgxqWSXIy2E3ylmeMqcdRm8=";
  };

  nativeBuildInputs = [
    cmake
    qt6.wrapQtAppsHook
    autoPatchelfHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
  ];

  postPatch = ''
    # Fix hardcoded output directory
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ''${CMAKE_SOURCE_DIR}/bin)' "" \
      --replace-fail 'set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ''${CMAKE_SOURCE_DIR}/bin)' "" \
      --replace-fail 'set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ''${CMAKE_SOURCE_DIR}/bin)' ""

    # Fix INSTALL_RPATH; autoPatchElfHook handles the rest
    substituteInPlace CMakeLists.txt \
      --replace-fail 'INSTALL_RPATH "/usr/lib"' 'INSTALL_RPATH "$out/lib"'
  '';

  # CMakeLists.txt doesn't have install rules, so install manually
  installPhase = ''
    runHook preInstall

    install -Dm755 obsbot-gui $out/bin/obsbot-gui
    install -Dm755 obsbot-cli $out/bin/obsbot-cli

    install -Dm755 $src/sdk/lib/libdev.so.1.0.2 $out/lib/libdev.so.1.0.2
    ln -s libdev.so.1.0.2 $out/lib/libdev.so.1
    ln -s libdev.so.1.0.2 $out/lib/libdev.so

    install -Dm644 $src/obsbot-control.desktop $out/share/applications/obsbot-control.desktop
    install -Dm644 $src/resources/icons/camera.svg $out/share/icons/hicolor/scalable/apps/obsbot-control.svg

    runHook postInstall
  '';

  meta = with lib; {
    description = "Native Linux control app for OBSBOT cameras with PTZ, auto-framing, and live preview";
    homepage = "https://github.com/aaronsb/obsbot-camera-control";
    license = licenses.unfree; # bundled proprietary libdev.so
    platforms = [ "x86_64-linux" ];
    mainProgram = "obsbot-gui";
  };
}
