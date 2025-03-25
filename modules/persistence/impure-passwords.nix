{ config, pkgs, lib, ... }:

# handle creating passwords on impermanent systems without persisting /etc/shadow
let cfg = config.services.impermanent-user-passwords;
in {

  options.services.impermanent-user-passwords = {
    enable = lib.mkEnableOption
      "creates a passwordFile with an initial password before /etc/shadow is populated";

    username = lib.mkOption {
      type = lib.types.str;
      example = "user";
      description = ''
        username to create a passwordFile for
      '';
    };

    persistLocation = lib.mkOption {
      type = lib.types.str;
      example = "/nix/persist/secrets/\${user}passwordfile";
      description = ''
        Location to populate the  password file to
      '';
    };

    initialPassword = lib.mkOption {
      type = lib.types.str;
      example = "hunter2";
      description = ''
        initial password. this will be placed there if no password is already present.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    # systemd units don't activate early enough, and fileSystems doesn't either.
    # so write an activationScript which can populate the passwordFile when it's needed.
    system.activationScripts."populate-${cfg.username}-pwd" = {
      deps = [ "etc" ];
      text = ''
        set -e
        # If the parent dir does not already exist, create it.
        # Otherwise, does nothing, keeping existing permisions intact.
        mkdir -p --mode 0755 "${dirOf cfg.persistLocation}"
        if [ ! -f "${cfg.persistLocation}" ]; then
          # Write private key file with atomically-correct permissions.
          (set -e; umask 077; ${pkgs.mkpasswd}/bin/mkpasswd -m sha-512 "${cfg.initialPassword}" > ${cfg.persistLocation})
        fi
      '';
    };

    system.activationScripts.users.deps = [ "populate-${cfg.username}-pwd" ];

    # you need to create and change this when you install a new computer
    # use "mkpasswd -m sha-512 > path"
    # note that it should be readable by root only. (chown root:root / chmod 600)
    users.users.${cfg.username}.hashedPasswordFile = cfg.persistLocation;
  };
}
