{ lib
, powercord-unwrapped
, stdenvNoCC
, plugins ? { }
, themes ? { }
}:
let
  unwrapped = powercord-unwrapped.overrideAttrs (old: {
    patches = old.patches ++ [
      ./disable-back-handling.js.patch
      # ./force-new-backend.js.patch
    ];
  });
in
stdenvNoCC.mkDerivation {
  name = "powercord";
  src = unwrapped.out;

  installPhase =
    let
      fromDrvs = lib.mapAttrsToList
        (k: drv: {
          inherit (drv) outPath;
          name = lib.strings.sanitizeDerivationName k;
        });

      map = n: lib.concatMapStringsSep "\n"
        (e: ''
          chmod 755 $out/src/Powercord/${n}
          cp -a ${e.outPath} $out/src/Powercord/${n}/${e.name}
          chmod -R u+w $out/src/Powercord/${n}/${e.name}
        '');

      mappedPlugins = map "plugins" (fromDrvs plugins);
      mappedThemes = map "themes" (fromDrvs themes);
    in
    ''
      cp -a $src $out
      chmod 755 $out
      ln -s ${unwrapped.deps}/node_modules $out/node_modules
      ${mappedPlugins}
      ${mappedThemes}
    '';

  passthru.unwrapped = unwrapped;
  meta = unwrapped.meta // {
    priority = (unwrapped.meta.priority or 0) - 1;
  };
}
