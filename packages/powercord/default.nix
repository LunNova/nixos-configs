{ lib
, powercord-unwrapped
, stdenvNoCC
, plugins ? { }
, themes ? { }
}:
stdenvNoCC.mkDerivation {
  name = "powercord";
  src = powercord-unwrapped.out;

  installPhase =
    let
      fromDrvs = drvs: builtins.trace drvs (lib.mapAttrsToList
        (k: drv: {
          inherit (drv) outPath;
          name = lib.strings.sanitizeDerivationName k;
        })
        drvs);

      map = n: l: lib.concatMapStringsSep "\n"
        (e: ''
          chmod 755 $out/src/Powercord/${n}
          cp -a ${e.outPath} $out/src/Powercord/${n}/${e.name}
          chmod -R u+w $out/src/Powercord/${n}/${e.name}
        '')
        l;

      mappedPlugins = map "plugins" (fromDrvs plugins);
      mappedThemes = map "themes" (fromDrvs themes);
    in
    ''
      cp -a $src $out
      chmod 755 $out
      ln -s ${powercord-unwrapped.deps}/node_modules $out/node_modules
      ${mappedPlugins}
      ${mappedThemes}
    '';

  passthru.unwrapped = powercord-unwrapped;
  meta = powercord-unwrapped.meta // {
    priority = (powercord-unwrapped.meta.priority or 0) - 1;
  };
}
