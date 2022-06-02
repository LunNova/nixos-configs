{ edk2
, util-linux
, nasm
, python3
, ...
}:
(edk2.mkDerivation "ShellPkg/ShellPkg.dsc" {
  pname = "edk2-uefi-shell";
  inherit (edk2) version;
  nativeBuildInputs = [ util-linux nasm python3 ];
  noAuditTmpdir = true;
  strictDeps = true;
  dontPatchELF = true;
  dontStrip = true;
  FULL_SHELL_GUID = "EA4BB293-2D7F-4456-A681-1F22F42CD0BC";
  installPhase = ''
    runHook preInstall
    mkdir -p $out/
    cp Build/Shell/RELEASE*/*/Shell_"$FULL_SHELL_GUID".efi $out/shell.efi
    runHook postInstall
  '';
}).overrideAttrs (finalAttrs: previousAttrs: {
  passthru.efi = "${finalAttrs.finalPackage}/shell.efi";
})
