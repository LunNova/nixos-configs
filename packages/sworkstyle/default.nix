{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "sworkstyle";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "Lyr-7D1h";
    repo = "swayest_workstyle";
    rev = version;
    sha256 = "sha256-X0Yu6jDEGRByko0GPx5qICt8PW1OclRroE8XvJ1iATE=";
  };

  cargoSha256 = "sha256-/nWdQOovO9RfeoIcgw8ifpUeKXJIgnvBjTZfpDFlGt8=";

  meta = with lib; {
    homepage = "https://github.com/Lyr-7D1h/swayest_workstyle";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
