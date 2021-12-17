{ lib, python3, pkgs, pkgconfig }:

let rev = "2803bb841e19232ec08c57bdfca66d0535131dab"; in
pkgs.python3Packages.buildPythonApplication rec {
  pname = "key-mapper";
  version = "1.2.1";

  src = pkgs.fetchFromGitHub {
    inherit rev;
    owner = "sezanzeb";
    repo = "key-mapper";
    sha256 = "07dgp4vays1w4chhd22vlp9bxc49lcgzkvmjqgbr00m3781yjsf7";
  };

  patches = [ ];
  # if debugging
  # substituteInPlace keymapper/logger.py --replace "logger.setLevel(logging.INFO)"  "logger.setLevel(logging.DEBUG)"
  prePatch = ''
    echo "COMMIT_HASH = '${rev}'" > keymapper/commit_hash.py
    substituteInPlace keymapper/data.py --replace "/usr/share/key-mapper"  "$out/usr/share/key-mapper"
  '';

  doCheck = false; # fails atm as can't import modules when testing due to some sort of path issue
  pythonImportsCheck = [
    "evdev"
    "keymapper"
  ];

  # Nixpkgs 15.9.4.3. When using wrapGAppsHook with special derivers you can end up with double wrapped binaries.
  dontWrapGApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  nativeBuildInputs = with pkgs; [
    wrapGAppsHook
    gettext
    gtk3
    git
    glib
    gobject-introspection
    pkgs.xlibs.xmodmap
    python3.pkgs.pygobject3
  ];

  propagatedBuildInputs = with python3.pkgs; [
    setuptools # needs pkg_resources
    pygobject3
    evdev
    pkgconfig
    pydbus
    psutil
    pkgs.xlibs.xmodmap
  ];

  postInstall = ''
    sed -r "s#RUN\+\=\"/bin/key-mapper-control#RUN\+\=\"$out/bin/key-mapper-control#g" -i data/key-mapper.rules
    sed -r "s#ExecStart\=/usr/bin/key-mapper-service#ExecStart\=$out/bin/key-mapper-service#g" -i data/key-mapper.service
    sed -r "s#WantedBy\=default.target#WantedBy\=graphical.target#g" -i data/key-mapper.service

    install -D -t $out/share/applications/ data/*.desktop
    install -D data/key-mapper.rules $out/etc/udev/rules.d/99-key-mapper.rules
    install -D data/key-mapper.service $out/lib/systemd/system/key-mapper.service
    install -D data/key-mapper.policy $out/share/polkit-1/actions/key-mapper.policy
    install -D data/keymapper.Control.conf $out/etc/dbus-1/system.d/keymapper.Control.conf
    install -D -t $out/usr/share/key-mapper/ data/*
    install -m755 -D -t $out/bin/ bin/*
  '';

  meta = {
    platforms = lib.platforms.unix;
  };
}
