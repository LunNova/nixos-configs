{ pkgs, config, lib, lun-profiles, ... }:
{
  home.packages = with pkgs; [
    # osu-lazer not currently playing
    prismlauncher # Hi emstar (:
  ] ++ lib.optionals (lun-profiles.wineGaming or false) [
    lun.lutris
    pkgs.lun.wine
    # TODO: try bottles instead of lutris
  ];

  xdg.configFile."openxr/1/active_runtime.json".source = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
  xdg.configFile."openvr/openvrpaths.vrpath".text = ''
    {
      "config": ["${config.xdg.dataHome}/Steam/config"],
      "external_drivers": null,
      "jsonid": "vrpathreg",
      "log": ["${config.xdg.dataHome}/Steam/logs"],
      "runtime" : ["${pkgs.opencomposite}/lib/opencomposite"],
      "version" : 1
    }
  '';
}
