{ lib
, buildPythonApplication
, fetchPypi
, poetry-core
, click
, rmscene
}:
buildPythonApplication rec {
  pname = "rmc";
  version = "0.3.0";
  pyproject = true;

  propagatedBuildInputs = [
    click
    rmscene
  ];

  nativeBuildInputs = [
    poetry-core
  ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-V6/hTVZpQIW2o4KqK5O3uG6yHpPnILFqgpkKoNZRPcs=";
  };

  pythonRelaxDeps = [
    "rmscene"
  ];

  meta = {
    description = "Convert to/from v6 .rm files from the reMarkable tablet";
    homepage = "https://pypi.org/project/rmc/";
    license = lib.licenses.mit;
    maintainers = [
      lib.maintainers.LunNova
    ];
    changelog = "https://github.com/ricklupton/rmc/releases"; # Placeholder - verify actual repo
    platforms = lib.platforms.unix; # It's a Python script, so it should run on most Unix-like systems.
  };
}
