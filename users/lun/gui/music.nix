{ pkgs, flakeArgs, lib, ... }:
let foobar2000 = flakeArgs.erosanix.packages.${pkgs.system}.foobar2000 or null;
in
{
  home.packages = lib.mkIf (foobar2000 != null) [ foobar2000 ];
}
