{ lib
, python3
, pkgs
, pkgconfig
, input_remapper_version ? "1.3.0"
, input_remapper_src_rev ? "76c3cadcfaa3f244d62bd911aa6642a86233ffa0"
, input_remapper_src_hash ? "sha256-llSgPwCLY34sAmDEuF/w2qeXdPFLLo1MIPBmbxwZZ3k="
}:

pkgs.python3Packages.buildPythonApplication {
  pname = "input-remapper";
  version = input_remapper_version;

  src = pkgs.fetchFromGitHub {
    rev = input_remapper_src_rev;
    owner = "sezanzeb";
    repo = "input-remapper";
    sha256 = "sha256-llSgPwCLY34sAmDEuF/w2qeXdPFLLo1MIPBmbxwZZ3k=";
  };

  # Fixes error
  # Couldn’t recognize the image file format for file "*.svg"
  # at startup, see https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  patches = [ ];
  # if debugging
  # substituteInPlace inputremapper/logger.py --replace "logger.setLevel(logging.INFO)"  "logger.setLevel(logging.DEBUG)"
  prePatch = ''
    echo "COMMIT_HASH = '${input_remapper_src_rev}'" > inputremapper/commit_hash.py
    substituteInPlace inputremapper/data.py --replace "/usr/share/input-remapper"  "$out/usr/share/input-remapper"
    substituteInPlace inputremapper/system_mapping.py --replace '["xmodmap", "-pke"]' '["${pkgs.xlibs.xmodmap}/bin/xmodmap", "-pke"]'
  '';

  doCheck = false; # fails atm as can't import modules when testing due to some sort of path issue
  pythonImportsCheck = [
    "evdev"
    "inputremapper"
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

  # FIXME: don't install udev rules for now due to issue with hanging event handler
  postInstall = ''
    # sed -r "s#RUN\+\=\"/bin/input-remapper-control#RUN\+\=\"$out/bin/input-remapper-control#g" -i data/99-input-remapper.rules
    sed -r "s#ExecStart\=/usr/bin/input-remapper-service#ExecStart\=$out/bin/input-remapper-service#g" -i data/input-remapper.service
    sed -r "s#WantedBy\=default.target#WantedBy\=graphical.target#g" -i data/input-remapper.service

    chmod +x data/*.desktop

    install -D -t $out/share/applications/ data/*.desktop
    install -D -t $out/share/polkit-1/actions/ data/input-remapper.policy
    install -D data/99-input-remapper.rules $out/etc/udev/rules.d/99-input-remapper.rules
    install -D data/input-remapper.service $out/lib/systemd/system/input-remapper.service
    install -D data/input-remapper.policy $out/share/polkit-1/actions/input-remapper.policy
    install -D data/inputremapper.Control.conf $out/etc/dbus-1/system.d/inputremapper.Control.conf
    install -D -t $out/usr/share/input-remapper/ data/*

    # Only install input-remapper prefixed binaries, we don't care about deprecated key-mapper ones
    install -m755 -D -t $out/bin/ bin/input-remapper*
  '';

  meta = {
    platforms = lib.platforms.unix;
  };
}
