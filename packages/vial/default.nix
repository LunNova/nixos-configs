{ lib
, writeTextFile
, fetchFromGitHub
, stdenv
, python3Packages
, wrapQtAppsHook
}:
let
  # fbs_runtime ported to 3.x - https://github.com/rnbwdsh/fbs
  fbs = python3Packages.buildPythonPackage {
    pname = "fbs_runtime";
    version = "1.0";
    src = fetchFromGitHub {
      name = "fbs-src";
      owner = "rnbwdsh";
      repo = "fbs";
      rev = "c5fc40b65ff4419654fa37041b13ee886165b966";
      hash = "sha256-8JYCu8LhZjx9I/BfisVXvEQxDDEiKvZpOcOYfrBiu50=";
    };
    # we don't care about PyInstaller because we're only using fbs's runtime capabilities
    # not the installer generator
    postPatch = ''
      sed -i s/pyinstaller// requirements.txt
      sed -i "s/'PyInstaller'//" setup.py
    '';
    # checks want the installer to work
    doCheck = false;
  };

  udev-rule-vial-serial = writeTextFile {
    name = "vial-udev";
    text = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
    destination = "/etc/udev/rules.d/99-vial.rules";
  };
  udev-rule-all-hidraw = writeTextFile {
    name = "vial-udev";
    text = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
    destination = "/etc/udev/rules.d/99-vial-all-hidraw.rules";
  };
  propagatedBuildInputs = with python3Packages; [
    setuptools
    altgraph
    future
    keyboard
    # FIXME: is this needed?
    # macholib
    pefile
    pyqt5
    sip
    certifi
    fbs
    simpleeval
    hidapi
  ];
in
stdenv.mkDerivation (final: {
  pname = "vial";
  version = "0.7.1";

  src = fetchFromGitHub {
    name = "vial-gui-src";
    owner = "vial-kb";
    repo = "vial-gui";
    rev = "v${final.version}";
    hash = "sha256-1p0X6sovLboYn576GTlmZYNa+riwEBLwzDbbNzrcDiY=";
  };

  inherit propagatedBuildInputs;

  nativeBuildInputs = with python3Packages; [
    wrapQtAppsHook
    wrapPython
    pyqt5
    python
  ];

  dontWrapQtApps = true;

  makeWrapperArgs = [
    "\${qtWrapperArgs[@]}"
  ];

  preInstall = ''
    mkdir -p $out/bin/ $out/vial/
    # full package
    cp -R ./* $out/vial/
    # launch script
    echo "#!/usr/bin/env bash"  >> $out/bin/vial
    echo "cd $out/vial"  >> $out/bin/vial
    echo "exec $out/vial/src/main/python/main.py" >> $out/bin/vial
    chmod +x $out/bin/vial

    # make main.py executable
    sed -i '1s|^|#!/usr/bin/env python\n|' $out/vial/src/main/python/main.py
    chmod +x $out/vial/src/main/python/main.py
  '';

  postFixup = ''
    [ -d "$out/vial/src/main/python/" ]
    wrapPythonProgramsIn "$out/vial/src/main/python/" "$out $$propagatedBuildInputs"
  '';

  passthru = {
    inherit udev-rule-all-hidraw udev-rule-vial-serial;
  };

  meta = {
    description = "An Open-source GUI and QMK fork for configuring your keyboard in real time";
    homepage = "https://get.vial.today";
    license = lib.licenses.gpl2Plus;
    mainProgram = "vial";
    maintainers = with lib.maintainers; [ LunNova ];
    platforms = lib.platforms.linux;
  };
})
