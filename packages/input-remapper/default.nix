{ lib
, python3
, pkgconfig
, wrapGAppsHook
, gettext
, gtk3
, glib
, gobject-introspection
, xmodmap ? null # safe to override to null if you don't want xmodmap support
, pygobject3
, setuptools
, evdev
, pydbus
, psutil
, fetchFromGitHub
, buildPythonApplication
, procps
, findutils
, withDebugLogLevel ? false
, input_remapper_version ? "1.3.0"
, input_remapper_src_rev ? "76c3cadcfaa3f244d62bd911aa6642a86233ffa0"
, input_remapper_src_hash ? "sha256-llSgPwCLY34sAmDEuF/w2qeXdPFLLo1MIPBmbxwZZ3k="
}:

buildPythonApplication {
  pname = "input-remapper";
  version = input_remapper_version;

  src = fetchFromGitHub {
    rev = input_remapper_src_rev;
    owner = "sezanzeb";
    repo = "input-remapper";
    sha256 = input_remapper_src_hash;
  };

  # Fixes error
  # Couldn’t recognize the image file format for file "*.svg"
  # at startup, see https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  prePatch = ''
    # set revision for --version output
    echo "COMMIT_HASH = '${input_remapper_src_rev}'" > inputremapper/commit_hash.py

    # fix FHS paths
    substituteInPlace inputremapper/data.py \
      --replace "/usr/share/input-remapper"  "$out/usr/share/input-remapper"

    # no UI tests are ran, don't try to require Gtk at start of tests
    substituteInPlace tests/test.py \
      --replace 'gi.require_version("GtkSource", "4")' ""

    # fix exit code for test script
    # TODO: upstream
    substituteInPlace tests/test.py \
      --replace 'unittest.TextTestRunner(verbosity=2).run(testsuite)' 'sys.exit(not unittest.TextTestRunner(verbosity=2).run(testsuite).wasSuccessful())'

    # fix test_rename_config
    # TODO remove after release includes
    # https://github.com/sezanzeb/input-remapper/commit/47bcefa7f382abc4c7b00cc9876262406c1615d2#diff-8bf02d9f9d1d918900aae47ea75ecd7d1330e2b0a34738b710be164dfbd31d3bL65
    substituteInPlace tests/testcases/test_migrations.py \
      --replace 'os.rmdir(new)' 'import shutil;shutil.rmtree(new)'

    # use build dir not /tmp
    # TODO remove after https://github.com/sezanzeb/input-remapper/pull/264 is merged and released
    ${findutils}/bin/find tests -iname '*.py' | while read file; do substituteInPlace "$file" --replace '"/tmp' '"/build/tmp'; done
  '' + (lib.optionalString (withDebugLogLevel) ''
    # if debugging
    substituteInPlace inputremapper/logger.py --replace "logger.setLevel(logging.INFO)"  "logger.setLevel(logging.DEBUG)"
  '');

  doCheck = true;
  checkInputs = [
    xmodmap
    procps
  ];
  disabledTests = [ ];
  pythonImportsCheck = [
    "evdev"
    "inputremapper"
  ];

  # Custom test script, can't use plain pytest / pytestCheckHook
  # We only run tests which don't need UI or dbus
  # Skipped
  # test_daemon (dbus)
  # test_gui (UI)
  # test_data (checks for /usr and writable dir, not with nix)
  # test_injector (not in the sandbox)
  # test_macros, test_reader, test_keycode_mapper, test_consumer_control (relies on sleeping during tests or checking how long slept for so fails on slow system or high load)
  installCheckPhase = (lib.optionalString (xmodmap != null) ''
    export PATH=${lib.makeBinPath [ xmodmap ]}:$PATH
  '') + ''
    mkdir /build/tmp
    python tests/test.py \
      test_config \
      test_context \
      test_control \
      test_dev_utils \
      test_event_producer \
      test_groups \
      test_ipc \
      test_key \
      test_logger \
      test_mapping \
      test_migrations \
      test_paths \
      test_presets \
      test_user
  '';

  # Nixpkgs 15.9.4.3. When using wrapGAppsHook with special derivers you can end up with double wrapped binaries.
  dontWrapGApps = true;
  preFixup = ''
    makeWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
      --prefix PATH : "${lib.makeBinPath [ xmodmap ]}"
    )
  '';

  nativeBuildInputs = [
    wrapGAppsHook
    gettext
    gtk3
    glib
    gobject-introspection
    pygobject3
    xmodmap
  ];

  propagatedBuildInputs = [
    setuptools # needs pkg_resources
    pygobject3
    evdev
    pkgconfig
    pydbus
    psutil
    xmodmap
  ];

  postInstall = ''
    sed -r "s#RUN\+\=\"/bin/input-remapper-control#RUN\+\=\"$out/bin/input-remapper-control#g" -i data/99-input-remapper.rules
    sed -r "s#ExecStart\=/usr/bin/input-remapper-service#ExecStart\=$out/bin/input-remapper-service#g" -i data/input-remapper.service

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

  meta = with lib; {
    description = "An easy to use tool to change the mapping of your input device buttons";
    homepage = "https://github.com/sezanzeb/input-remapper";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ]; # TODO: maintainers entry LunNova ];
  };
}
