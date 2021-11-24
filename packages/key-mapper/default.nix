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
  };

  patches = [ ];

  doCheck = false; # fails atm as can't import modules when testing due to some sort of path issue

  nativeBuildInputs = with pkgs; [ gettext gtk3 git glib gobject-introspection pkgs.xlibs.xmodmap ];

  buildInputs = with python3.pkgs; [ python3 pkgconfig pygobject3 evdev pydbus psutil pkgs.xlibs.xmodmap ] ++ nativeBuildInputs;

  meta = {
    platforms = lib.platforms.unix;
  };
}