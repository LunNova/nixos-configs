{ lib
, python3
, wrapGAppsHook
, gobject-introspection
, fetchFromGitHub
, libnotify
}:

let
  ratbag-python = python3.pkgs.buildPythonPackage {
    pname = "ratbag-python";
    version = "unstable-2023-08-25";
    pyproject = true;
    src = fetchFromGitHub {
      owner = "kyokenn";
      repo = "ratbag-python";
      rev = "f24d798c6c44f3ec1c4c64cd3f349f178fdf2163";
      hash = "sha256-uOqYXbGqUO92BlMKgy4VzRU9W23ADh94OfhCWdmsrmU=";
    };

    nativeBuildInputs = [
    ];

    propagatedBuildInputs = with python3.pkgs; [
      setuptools
      wheel
      attrs
      pyudev
      libevdev
      pyyaml
      click
    ];

    # pythonImportsCheck = [ "ratbag" ];
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "rogdrv";
  version = "unstable-2023-08-25";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kyokenn";
    repo = "rogdrv";
    rev = "9fff99341bbedd7de005049bab16b1e2d204a758";
    hash = "sha256-pXWQdgI8VyDs1FU1EAfV46SEx+eDacCnDZCknIosnpE=";
    fetchSubmodules = true;
  };

  dontWrapGApps = true;

  nativeBuildInputs = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
    wrapGAppsHook
    gobject-introspection
  ];

  propagatedBuildInputs = [
    libnotify.dev
    python3.pkgs.setuptools
    python3.pkgs.wheel
    ratbag-python
    python3.pkgs.pygobject3
  ];

  pythonImportsCheck = [ "rog" ];

  preInstall = ''
    mkdir -p $out/etc/udev/rules.d/
    cp udev/* $out/etc/udev/rules.d/
  '';

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  meta = with lib; {
    description = "ASUS ROG userspace mouse driver for Linux";
    homepage = "https://github.com/kyokenn/rogdrv";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ LunNova ];
    mainProgram = "rogdrv";
  };
}
