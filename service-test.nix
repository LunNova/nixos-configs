_:
# everything for unprivileged service testing is here except a bit of deploy boilerplate/getting inputs to the right place
# which is under testSingleServiceDeployAsLunOnLocalhost in flake.nix
let
  self = {
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
    helloWorldModule = { pkgs, ... }: {
      systemd.user.services = {
        hello = {
          Unit = {
            Description = "Hello World";
            Documentation = "man:hello(1)";
            PartOf = "default.target";
          };
          Service = {
            Type = "simple";
            Restart = "never";
            ExecStart = "${pkgs.hello}/bin/hello";
          };
          Install = { WantedBy = [ "default.target" ]; };
        };
      };
    };
    hmProfile = { user, modules, hm, deploy-rs, pkgs, lib }: self.profile {
      inherit user;
      activationScript = deploy-rs.lib.${pkgs.system}.activate.custom
        (self.singleServiceDeployScript {
          homeEnvironment = hm {
            inherit pkgs;
            check = true;
            configuration = {
              _module.args.pkgs = lib.mkForce pkgs;
              # don't do i686 backcompat pkgs
              _module.args.pkgs_i686 = lib.mkForce { };
              home.homeDirectory = "/home/${user}";
              home.username = "${user}";
              home.stateVersion = "23.05";
            };
          };
        }) "./bin/activate-services";
    };
    profile = { user, activationScript }: {
      sshUser = user;
      inherit user;
      path = activationScript;
    };
    singleServiceDeployScript = { homeEnvironment }:
      homeEnvironment.pkgs.buildEnv {
        name = "deployProfile";
        paths = [
          (homeEnvironment.pkgs.writeShellScriptBin "activate-services" ''
            mkdir -p $HOME/.local/systemd/
            # FIXME: remove old services? probably need a unique prefix per deploy script or something?
            cp -r ${homeEnvironment.activationPackage}/home-files/.config/systemd/** $HOME/.local/systemd/
            # FIXME: this won't start the units / depend on them starting successfully?
          '')
        ];
      };
  };
in
self
