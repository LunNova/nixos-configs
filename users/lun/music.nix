{ pkgs, lun, ... }:
{
  home.packages = with pkgs; [
    lun.args.erosanix.packages.${pkgs.system}.foobar2000
  ];
}
