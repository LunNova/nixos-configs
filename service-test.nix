_:
{
  # nixos module for host system which enables systemd lingering
  # lingering.users = [ "user1" "user2" ];
  # This allows systemd user services for these users to start on system boot.
  hostNixosModule = { pkgs, lib, config, ... }:
    let
      lingerTouch = lib.concatMapStringsSep "\n"
        (user: ''
          touch /var/lib/systemd/linger/${user}
        '')
        config.lingering.users;
    in
    {
      options = {
        lingering = {
          users = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = false;
            description = ''
              Enable lingering for the subset of users that are declared in
              `users.users`.
            '';
          };
        };
      };
      config = {
        system.activationScripts = {
          enableLingering = ''
            # remove all existing lingering users
            rm -r /var/lib/systemd/linger
            mkdir /var/lib/systemd/linger
            # enable for the subset of declared users
            ${lingerTouch}
          '';
        };
      };
    };
  node = flakeArgs: self: {
    hostname = "localhost";
    profiles.system = {
      sshUser = "lun";
      user = "root";
      path = flakeArgs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router-nixos;
    };
  };
  singleServiceDeployProfile = { pkgs, homeEnvironment, services, ... }:
    {
      profile = pkgs.buildEnv
        {
          name = "deployProfile";
          paths = [
            (pkgs.writeShellScriptBin "activate-services" { } ''
'')
            homeEnvironment.activationPackage
          ];
        };
    };
}
