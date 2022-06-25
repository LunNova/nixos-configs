# https://github.com/StardustXR/stardust-xr
{ lib
, stdenv
, flatbuffers
, glm
, ninja
, libxkbcommon
, fetchFromGitHub
, writeText
, meson
, cmake
, pkg-config
, perl
, wlroots
, wayland
, wayland-protocols
, libdrm
, mesa
, libGL
, xwayland
, libinput
, pixman
, seatd
, xcbutilwm
, libX11
, libcap
, xcbutilimage
, xcbutilerrors
, libpng
, ffmpeg_4
, xcbutilrenderutil
, vulkan-loader
, glslang
, openxr-loader
, fontconfig
, libxdg_basedir
, wayland-scanner
}:

let
  sxrLibSrc = fetchFromGitHub {
    owner = "StardustXR";
    repo = "libstardustxr";
    rev = "743acc7c300a4ff5c60934c226b98c0b60ad28fe";
    sha256 = "sha256-a0G2ahV11Fp2RJM+mw+7ZBUpZzfSeHhdMeg9Ltu85aU=";
  };
  sxrLib =
    stdenv.mkDerivation rec {
      pname = "libstardustxr";
      version = "unstable";
      src = sxrLibSrc;

      nativeBuildInputs = [
        meson
        ninja
        pkg-config
      ];

      buildInputs = [
        flatbuffers
        glm
        libxkbcommon
      ];
    };
in
stdenv.mkDerivation rec {
  pname = "stardust-xr";
  version = "unstable-2022-06-23";

  src = fetchFromGitHub {
    owner = "StardustXR";
    repo = "stardust-xr";
    rev = "86d8dcca39fe7dd544f0ae9cd854058264f2487a";
    fetchSubmodules = true;
    sha256 = "sha256-F5Xctfc6iCTglqAlVA/DA0Da1kG5ZffV66o4Vdby9lI=";
  };

  # FIXME: subprojects should be input packages
  # this ends up building its own wlroots as a subproject, should get it to use input wlroots
  # patch isn't right
  # same for xdg_utils_basedir
  postPatch = ''
    # sed -i 's/wlroots_proj = .*//g' CMakeLists.txt
    # sed -i 's/wlroots_server_protocols = .*//g' CMakeLists.txt
    # sed -i "s/wlroots = wlroots_proj.get_variable('wlroots')/wlroots = dependency('wlroots')/g" CMakeLists.txt
    # sed -i 's|wlroots_server_protocols\[\'xdg-shell\'\]|${wayland-protocols}|g" CMakeLists.txt
    # sed -i 's/xdg_utils_project =.*//g' meson.build
    # sed -i "s/xdg_utils_basedir = .*/xdg_utils_basedir = dependency('libxdg-basedir')/g" meson.build

    # CPM downloads packages from net, don't want that / can't in sandbox, use input packages
    sed -z 's/CPMAddPackage([^)]*)//g' -i subprojects/StereoKit/CMakeLists.txt
  '';

  nativeBuildInputs = [
    meson
    ninja
    cmake
    pkg-config
  ];

  dontStrip = true;
  mesonFlags = [ "--buildtype=debug" "--warnlevel=0" ];
  doCheck = true;
  strictDeps = true;

  # buildPhase = ''
  # meson build --prefix=$out/usr --buildtype=debug
  # cd build
  # ninja
  # '';
  # installPhase = ''
  # ninja install
  # '';

  buildInputs = [
    fontconfig
    openxr-loader
    sxrLib
    flatbuffers
    wayland
    wayland-protocols
    libdrm
    libGL
    mesa
    libxkbcommon
    libinput
    xwayland
    pixman
    seatd
    xcbutilwm
    libX11
    libcap
    xcbutilimage
    xcbutilerrors
    libpng
    ffmpeg_4
    xcbutilrenderutil
    vulkan-loader
    glslang
    libxdg_basedir
    wayland-scanner
  ];
}
