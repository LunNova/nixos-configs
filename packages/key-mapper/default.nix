{ lib, mach-nix, python3, pkgs, pkgconfig }:

# TODO: a mess, files get put directly in /usr/ and /etc and so on by the install script
# https://github.com/sezanzeb/key-mapper/blob/70bc804f15c3539c87add5dff7a2082b7358396e/setup.py#L110-L124

# mach-nix.buildPythonApplication {
#   src = builtins.fetchTarball { url = "https://github.com/sezanzeb/key-mapper/tarball/2803bb841e19232ec08c57bdfca66d0535131dab"; sha256 = "07dgp4vays1w4chhd22vlp9bxc49lcgzkvmjqgbr00m3781yjsf7"; };

#   nativeBuildInputs = with pkgs; [ gettext ];
#   #_.key-mapper.nativeBuildInputs.add = with mach-nix.nixpkgs; [ gettext ];
# }

pkgs.python3Packages.buildPythonApplication rec {
  pname = "key-mapper";
  version = "1.2.1";

  src = pkgs.fetchFromGitHub {
    owner = "sezanzeb/key-mapper";
    repo = "key-mapper";
    rev = version;
    sha256 = "07dgp4vays1w4chhd22vlp9bxc49lcgzkvmjqgbr00m3781yjsf7";
    leaveDotGit = true; # install script uses commit hash
  };

  patches = [ ];
  # if debugging
  # substituteInPlace keymapper/logger.py --replace "logger.setLevel(logging.INFO)"  "logger.setLevel(logging.DEBUG)"
  prePatch = ''
    substituteInPlace keymapper/data.py --replace "/usr/share/key-mapper"  "$out/usr/share/key-mapper"
  '';

  doCheck = false; # fails atm as can't import modules when testing due to some sort of path issue
  pythonImportsCheck = [
    "evdev"
    "keymapper"
  ];

  nativeBuildInputs = with pkgs; [
    gettext gtk3 git glib gobject-introspection pkgs.xlibs.xmodmap
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