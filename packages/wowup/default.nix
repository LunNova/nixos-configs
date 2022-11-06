{ appimageTools, fetchurl, gsettings-desktop-schemas, gtk3 }:
appimageTools.wrapType2 {
  # or wrapType1
  name = "wowup";
  src = fetchurl {
    url = "https://github.com/WowUp/WowUp.CF/releases/download/v2.9.1-beta.8/WowUp-CF-2.9.1-beta.8.AppImage";
    hash = "sha256-sdBOAlaiovWQlzv1QIFdEdp0BySd8EmHxwq8w0gfLPk=";
  };
  profile = ''
    export XDG_DATA_DIRS=${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:$XDG_DATA_DIRS
  '';
}
