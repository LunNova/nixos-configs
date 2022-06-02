{ lib, stdenv, fetchgit }:

stdenv.mkDerivation (finalAttrs: {
  pname = "memtest86+";
  version = "6.00-beta1+date=2022-06-01";

  src = fetchgit {
    url = "https://github.com/memtest86plus/memtest86plus";
    rev = "fae2ae9e13170dd9b7619c57acd05126c06f1642";
    hash = "sha256-zzsWJTT2DHr8W98VFNUgzmfNJRerpBYfBcAaGsnat7o=";
  };

  preBuild = ''
    cd ${if stdenv.isi686 then "build32" else "build64"}
  '';

  installPhase = ''
    install -Dm0444 -t $out/ memtest.bin memtest.efi
  '';

  dontPatchELF = true;
  dontStrip = true;

  passthru.efi = "${finalAttrs.finalPackage}/memtest.efi";

  meta = {
    homepage = "http://www.memtest.org/";
    description = "A tool to detect memory errors";
    license = lib.licenses.gpl2;
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
})
