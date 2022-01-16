{ lib
, stdenv
, fetchFromGitHub
, substituteAll
, swaybg
, meson_0_60
, ninja
, pkg-config
, wayland-scanner
, scdoc
, wayland
, libxkbcommon
, pcre
, json_c
, dbus
, libevdev
, pango
, cairo
, libinput
, libcap
, pam
, gdk-pixbuf
, librsvg
, wlroots
, wayland-protocols
, libdrm
, nixosTests
  # Used by the NixOS module:
, isNixOS ? false

, enableXWayland ? true
, nixpkgs-sway-path
}:

stdenv.mkDerivation rec {
  pname = "sway-unwrapped";
  version = "1.7-rc2";

  src = fetchFromGitHub {
    owner = "swaywm";
    repo = "sway";
    rev = version;
    sha256 = "1cl1wqh0j9z0i1xqn2cy3r6y6s3awgx1yb5p8nsvy1k58d8805pg";
  };

  patches = [
    "${nixpkgs-sway-path}load-configuration-from-etc.patch"

    (substituteAll {
      dep = "${nixpkgs-sway-path}";
      src = builtins.unsafeDiscardStringContext "${nixpkgs-sway-path}fix-paths.patch";
      inherit swaybg;
    })
  ];

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson_0_60
    ninja
    pkg-config
    wayland-scanner
    scdoc
  ];

  buildInputs = [
    wayland
    libxkbcommon
    pcre
    json_c
    dbus
    libevdev
    pango
    cairo
    libinput
    libcap
    pam
    gdk-pixbuf
    librsvg
    wayland-protocols
    libdrm
    (wlroots.override { inherit enableXWayland; })
  ];

  mesonFlags = [
    "-Dsd-bus-provider=libsystemd"
  ]
  ++ lib.optional (!enableXWayland) "-Dxwayland=disabled"
  ;

  passthru.tests.basic = nixosTests.sway;

  meta = with lib; {
    description = "An i3-compatible tiling Wayland compositor";
    longDescription = ''
      Sway is a tiling Wayland compositor and a drop-in replacement for the i3
      window manager for X11. It works with your existing i3 configuration and
      supports most of i3's features, plus a few extras.
      Sway allows you to arrange your application windows logically, rather
      than spatially. Windows are arranged into a grid by default which
      maximizes the efficiency of your screen and can be quickly manipulated
      using only the keyboard.
    '';
    homepage = "https://swaywm.org";
    changelog = "https://github.com/swaywm/sway/releases/tag/${version}";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ primeos synthetica ma27 ];
  };
}
