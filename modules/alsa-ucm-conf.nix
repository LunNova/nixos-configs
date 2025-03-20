{ pkgs, config, ... }:
let
  alsa-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "alsa-project";
      repo = "alsa-ucm-conf";
      rev = "b627bf6abe50b8bd84e455c6c0989b34b4b5803d";
      hash = "sha256-P/VsYNg/Qvy/iv0MYgX8Gt1mZXziIh10O9f9R6t4KL8=";
    };
    installPhase =
      ''
        runHook preInstall

        substituteInPlace ucm2/lib/card-init.conf \
          --replace-fail "/bin/rm" "${pkgs.coreutils}/bin/rm" \
          --replace-fail "/bin/mkdir" "${pkgs.coreutils}/bin/mkdir"

        substituteInPlace "ucm2/common/ctl/led.conf" \
            --replace-fail '/sbin/modprobe' '${pkgs.kmod}/bin/modprobe'

        mkdir -p $out/share/alsa
        cp -r ucm ucm2 $out/share/alsa

        runHook postInstall
      '';
  };
  env = {
    ALSA_CONFIG_UCM = "${alsa-ucm-conf}/share/alsa/ucm";
    ALSA_CONFIG_UCM2 = "${alsa-ucm-conf}/share/alsa/ucm2";
  };
in
{
  environment.systemPackages = [ alsa-ucm-conf ];
  environment.variables = env;
  environment.sessionVariables = env;
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM = config.environment.variables.ALSA_CONFIG_UCM;
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = config.environment.variables.ALSA_CONFIG_UCM2;
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM = config.environment.variables.ALSA_CONFIG_UCM;
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 = config.environment.variables.ALSA_CONFIG_UCM2;
}
