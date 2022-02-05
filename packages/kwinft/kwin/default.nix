{ stdenv
, lib
, extra-cmake-modules
, kdoctools
, fetchFromGitLab
, libepoxy
, lcms2
, libICE
, libSM
, libcap
, libdrm
, libinput
, libxkbcommon
, mesa
, pipewire
, udev
, wayland
, xcb-util-cursor
, xwayland
, qtdeclarative
, qtmultimedia
, qtquickcontrols2
, qtscript
, qtsensors
, qtvirtualkeyboard
, qtx11extras
, breeze-qt5
, kactivities
, kcompletion
, kcmutils
, kconfig
, kconfigwidgets
, kcoreaddons
, kcrash
, kdeclarative
, kdecoration
, kglobalaccel
, ki18n
, kiconthemes
, kidletime
, kinit
, kio
, knewstuff
, knotifications
, kpackage
, krunner
, kscreenlocker
, kservice
, kwayland
, kwayland-server
, kwidgetsaddons
, kwindowsystem
, kxmlgui
, plasma-framework
, libqaccessibilityclient
, #kwinft
  wlroots
, kwinft
, pkgconfig
, pixman
}:

stdenv.mkDerivation rec {
  pname = "kwinft";
  version = "1.0.0";

  dontWrapQtApps = true;

  src = fetchFromGitLab {
    owner = "kwinft";
    repo = pname;
    rev = "13be8a5795369b6744a5b4a1cb80dc781144cab8";
    sha256 = "sha256-DhwduF3LwvJZ6IuOBunWRanE4GN7Qf43SDv1Rj50bxY=";
  };

  patches = [
    ./0003-plugins-qpa-allow-using-nixos-wrapper.patch
    ./0002-xwayland.patch
    ./0001-follow-symlinks.patch
    ./0001-NixOS-Unwrap-executable-name-for-.desktop-search.patch
  ];

  outputs = [ "out" "dev" ];
  CXXFLAGS = [
    ''-DNIXPKGS_XWAYLAND=\"${lib.getBin xwayland}/bin/Xwayland\"''
  ];
  cmakeFlags = [ "-DCMAKE_SKIP_BUILD_RPATH=OFF" ];
  postInstall = ''
    # Some package(s) refer to these service types by the wrong name.
    # I would prefer to patch those packages, but I cannot find them!
    ln -s ''${!outputBin}/share/kservicetypes5/kwineffect.desktop \
          ''${!outputBin}/share/kservicetypes5/kwin-effect.desktop
    ln -s ''${!outputBin}/share/kservicetypes5/kwinscript.desktop \
          ''${!outputBin}/share/kservicetypes5/kwin-script.desktop
  '';

  nativeBuildInputs = [ pkgconfig extra-cmake-modules kdoctools ];

  buildInputs = [
    libepoxy
    lcms2
    libICE
    libSM
    libcap
    libdrm
    libinput
    libxkbcommon
    mesa
    pipewire
    udev
    wayland
    xcb-util-cursor
    xwayland

    qtdeclarative
    qtmultimedia
    qtquickcontrols2
    qtscript
    qtsensors
    qtvirtualkeyboard
    qtx11extras

    breeze-qt5
    kactivities
    kcmutils
    kcompletion
    kconfig
    kconfigwidgets
    kcoreaddons
    kcrash
    kdeclarative
    kdecoration
    kglobalaccel
    ki18n
    kiconthemes
    kidletime
    kinit
    kio
    knewstuff
    knotifications
    kpackage
    krunner
    kscreenlocker
    kservice
    kwayland
    kwayland-server
    kwidgetsaddons
    kwindowsystem
    kxmlgui
    plasma-framework
    libqaccessibilityclient

    wlroots
    kwinft.wrapland
    kwinft.disman
    pixman
  ];
}
