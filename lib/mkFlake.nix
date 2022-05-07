# Originally from @tejing1 https://github.com/tejing1/nixos-config
# with minor changes to support non-flake inputs and take packages as an arg on use
{ self, bootstrapLib }:
let
  inherit (builtins) mapAttrs concatMap attrValues toJSON listToAttrs;
  inherit (bootstrapLib) nameValuePair mapAttrsToList;
  inherit (bootstrapLib.strings) escapeNixIdentifier escapeNixString;
  concatStrings = builtins.concatStringsSep "";

  cleanNode = flake:
    let
      sourceInfo = flake.sourceInfo or flake;
      spec = { type = "path"; path = sourceInfo.outPath;inherit (sourceInfo) narHash; };
    in
    { inputs = mapAttrs (_: cleanNode) (flake.inputs or { }); locked = spec; original = spec; };

  flattenNode = prefix: node:
    let
      ids = mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).name) node.inputs;
      nod = concatMap (x: x) (attrValues (mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).value) node.inputs or { }));
    in
    nameValuePair prefix ([ (nameValuePair prefix (node // { inputs = ids; })) ] ++ nod);
in
{
  mkFlake =
    pkgs:
    flakeInputs:
    let
      inputsCode = "{${concatStrings (
    mapAttrsToList (n: v: "${escapeNixIdentifier n}.url=${escapeNixString "path:${v.sourceInfo.outPath}?narHash=${v.sourceInfo.narHash}"};") flakeInputs
  )}}";
      rootNode = { inputs = mapAttrs (_: cleanNode) flakeInputs; };
      lockJSON = toJSON {
        version = 7;
        root = "self";
        nodes = listToAttrs (flattenNode "self" rootNode).value;
      };
    in

    outputsCode:

    pkgs.runCommand "source" { } ''
      mkdir -p $out
      cat <<"EOF" >$out/flake.nix
      {inputs=${inputsCode};outputs=${outputsCode};}
      EOF
      cat <<"EOF" >$out/flake.lock
      ${lockJSON}
      EOF
    '';
}
