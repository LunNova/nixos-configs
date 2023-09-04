{ lib
, writeText
, writeTextFile
, writeShellScript
, fetchFromGitHub
, python3Packages
, wrapQtAppsHook
}:
let
  inherit (python3Packages) python;
  pname = "vial";
  version = "unstable-20230903";

  src = fetchFromGitHub {
    name = "vial-gui-src";
    owner = "vial-kb";
    repo = "vial-gui";
    rev = "5c198e1ec60f3dfe3376503f35291b7ee7b4ced8";
    hash = "sha256-PtCTzqrwmUJy/jMNRothFlF2Fs4GEQGOqUfy3yV4Un8=";
  };

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

  setupPy = writeText "setup.py" ''
    #!/usr/bin/env python

    from distutils.core import setup
    from setuptools import find_packages

    setup(name='vial',
      version='1.0',
      package_dir={"": 'src/main/python'},
      packages=find_packages(where='src/main/python'),
    )
  '';
  udev-rule-vial-serial = writeTextFile {
    name = "vial-udev";
    contents = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
    destination = "/etc/udev/rules.d/99-vial.rules";
  };
  udev-rule-all-hidraw = writeTextFile {
    name = "vial-udev";
    contents = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
    destination = "/etc/udev/rules.d/99-vial-all-hidraw.rules";
  };
in
(python3Packages.buildPythonApplication {
  inherit pname src version;
  format = "pyproject";

  postPatch = ''
    cp "${setupPy}" ./setup.py
    sed -i '1s|^|#!/usr/bin/env python\n|' src/main/python/main.py
    chmod +x src/main/python/main.py
  '';

  nativeBuildInputs = with python3Packages; [
    wrapQtAppsHook
    pyqt5
  ];

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

  doCheck = false;
  dontWrapQtApps = true;

  makeWrapperArgs = [
    "\${qtWrapperArgs[@]}"
  ];

  # mv $out/bin/${name} $out/bin/${pname}
  # install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
  # cp -r ${appimageContents}/usr/share/icons $out/share
  preInstall = ''
    mkdir -p $out/bin/ $out/vial/
    # full package
    cp -R ./* $out/vial/
    # launch script
    echo "#!/usr/bin/env bash"  >> $out/bin/vial
    echo "cd $out/vial"  >> $out/bin/vial
    echo "$out/vial/src/main/python/main.py" >> $out/bin/vial
    chmod +x $out/bin/vial
  '';

  postFixup = ''
    [ -d "$out/vial/src/main/python/" ]
    wrapPythonProgramsIn "$out/vial/src/main/python/" "$out $pythonPath"
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
}) // { inherit version; }
