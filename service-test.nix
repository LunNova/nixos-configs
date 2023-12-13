_:
# everything for unprivileged service testing is here except a bit of deploy boilerplate/getting inputs to the right place
# which is under testSingleServiceDeployAsLunOnLocalhost in flake.nix
let
  self = {
    # nixos module for host system which enables systemd lingering
    # lingering.users = [ "user1" "user2" ];
    # This allows systemd user services for these users to start on system boot.
    hostNixosModule = { lib, config, ... }:
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
            Restart = "no";
            ExecStart = "${pkgs.hello}/bin/hello";
          };
          Install = { WantedBy = [ "default.target" ]; };
        };
      };
    };
    hmProfile = { user, modules, hm, deploy-rs, pkgs, lib, profileName, postActivate ? "" }:
      let
        marker = ".marker-services-${profileName}";
        homeEnvironment = hm {
          inherit pkgs;
          check = true;
          configuration = {
            imports = modules;
            _module.args.pkgs = lib.mkForce pkgs;
            # don't do i686 backcompat pkgs
            _module.args.pkgs_i686 = lib.mkForce { };
            home.homeDirectory = "/home/${user}";
            home.username = "${user}";
            home.stateVersion = "23.05";
          };
        };
        units = self.unitsFromHomeEnvironment {
          inherit pkgs marker profileName homeEnvironment;
        };
        activationScript = self.activationScriptForUnits { inherit pkgs marker profileName units postActivate; };
      in
      self.profile {
        inherit user;
        activationScript = deploy-rs.lib.${pkgs.system}.activate.custom activationScript "./bin/activate-services";
      };
    profile = { user, activationScript }: {
      sshUser = user;
      inherit user;
      path = activationScript;
    };
    unitsFromHomeEnvironment = { pkgs, homeEnvironment, marker, profileName }:
      homeEnvironment.pkgs.runCommandNoCC "units-${profileName}" { } ''
        mkdir -p "$out/units/"
        touch "$out/units/${marker}"
        shopt -s failglob
        shopt -s globstar
        cd "${homeEnvironment.activationPackage}/home-files/.config/systemd/user"
        for unit in **; do
          if [ -d "$unit" ]; then
            mkdir -p "$out/units/$unit"
          else
            ln -s "$(pwd)/$unit" "$out/units/$unit"
          fi
        done
      '';
    activationScriptForUnits = { pkgs, units, marker, profileName, postActivate }:
      pkgs.buildEnv {
        name = "deployProfile-${profileName}";
        paths = [
          (pkgs.writeShellScriptBin "activate-services" ''
            set -euo pipefail
            shopt -s failglob
            shopt -s globstar
            mkdir -p $HOME/.local/share/systemd/user/
            for unit in $HOME/.local/share/systemd/**; do
              if [ ! -d "$unit" ] && ([ -f "$(dirname $(readlink "$unit"))/${marker}" ] || [ -f "$(dirname $(readlink "$unit"))/../${marker}" ]); then
                echo >&2 "${profileName}: Removing stale unit $unit"
                rm "$unit"
              fi
            done
            cd "${units}/units"
            for unit in **; do
              if [ -d "$unit" ]; then
                mkdir -p "$HOME/.local/share/systemd/user/$unit"
              else
                echo >&2 "${profileName}: Installing unit $unit"
                ln -s "$(pwd)/$unit" "$HOME/.local/share/systemd/user/$unit"
              fi
            done
            # FIXME: this won't start the units / depend on them starting successfully
            # TODO:  systemctl --reverse list-dependencies --user hello -> if contains default.target should start
            # or if is currently running should reload/restart
            echo "${profileName}: Start/restart services manually, automating this is not yet implemented"
            ${postActivate}
          '')
        ];
      };
  };
in
self
