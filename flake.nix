{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nix-gaming.url = github:fufexan/nix-gaming;
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = github:NixOS/nixos-hardware/master;

    minimal-shell.url = "github:LunNova/nix-minimal-shell";

    # Powercord. pcp- and pct- prefix have meaning, cause inclusion as powercord plugin/theme
    powercord = { url = "github:powercord-org/powercord"; flake = false; };
    powercord-overlay = {
      url = "github:LavaDesu/powercord-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.powercord.follows = "powercord";
    };
    # TODO: check for web access loading scripts and patch out
    pcp-tweaks = { url = "github:NurMarvin/discord-tweaks"; flake = false; };
    pcp-theme-toggler = { url = "github:redstonekasi/theme-toggler"; flake = false; };
    pcp-better-status-indicators = { url = "github:GriefMoDz/better-status-indicators"; flake = false; };
    pcp-webhook-tag = { url = "github:BenSegal855/webhook-tag"; flake = false; };
    # TODO: locked version of this which doesn't hit web
    pct-clearvision = { url = "github:ClearVision/ClearVision-v6"; flake = false; };
    # TODO: background overrides here instead of manually configured?
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , pre-commit-hooks
    , nix-gaming
    , powercord-overlay
    , ...
    }@args:
    let
      system = "x86_64-linux";
      defaultPkgsConfig = {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlay powercord-overlay.overlay ];
      };
      mkPkgs = pkgs: extra:
        (import pkgs (recursiveMerge [ defaultPkgsConfig extra ]));
      recursiveMerge = attrList:
        let f = attrPath:
          with lib; with builtins;
          zipAttrsWith (n: values:
            if tail values == [ ]
            then head values
            else if all isList values
            then unique (concatLists values)
            else if all isAttrs values
            then f (attrPath ++ [ n ]) values
            else last values
          );
        in f [ ] attrList;
      filterInputs = prefix: lib.filterAttrs (name: value: (lib.hasPrefix prefix name)) args;
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      nixpkgs-unfree-path = ./hack-nixpkgs-unfree;
      nixpkgs-unfree-relocked = pkgs.stdenv.mkDerivation {
        name = "nixpkgs-unfree-relocked";
        outputs = [ "out" ];
        dontUnpack = true;
        fixupPhase = "";
        installPhase = ''
          mkdir -p $out
          cp -t $out ${nixpkgs-unfree-path}/{flake.nix,flake.lock,default.nix}
          substituteInPlace $out/default.nix --replace "nixpkgs = null" 'nixpkgs = "${args.nixpkgs}"'
          substituteInPlace $out/flake.lock --replace \
            "%REV%" "${lock.nodes.nixpkgs.locked.rev}" --replace \
            "%HASH%" "${lock.nodes.nixpkgs.locked.narHash}"
          substituteInPlace $out/flake.nix --replace \
            "%REV%" "${lock.nodes.nixpkgs.locked.rev}"
        '';
      };
      pkgs = mkPkgs args.nixpkgs { };
      lib = args.nixpkgs.lib;
      readModules = path: builtins.map (x: path + "/${x}") (builtins.attrNames (builtins.readDir path));
      makeHost = pkgs: path: lib.nixosSystem {
        inherit system;

        specialArgs =
          {
            nixos-hardware-modules-path = "${args.nixos-hardware}";
          };

        modules = [
          { nixpkgs.pkgs = pkgs; }
          {
            # pin system nixpkgs to the same version as the flake input
            # (don't see a way to declaratively set channels but this seems to work fine?)
            # TODO try https://github.com/tejing1/nixos-config/blob/df7f087c1ec0183422df22398d9b06c523adae84/nixosConfigurations/tejingdesk/registry.nix#L26-L28 approach
            nix.registry.pkgs.flake = nixpkgs-unfree-relocked;
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.nixPath = [ "pkgs=${nixpkgs-unfree-relocked}" ];
            system.configurationRevision = lib.mkIf (args.self ? rev) args.self.rev; # set configurationRevision if available
          }
          home-manager.nixosModules.home-manager
          nix-gaming.nixosModules.pipewireLowLatency
          path
          ./users
          {
            config = {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            };
          }
        ] ++ (readModules ./modules);
      };
    in
    {
      inherit args;

      caPkgs = mkPkgs args.nixpkgs {
        config.contentAddressedByDefault = true;
      };

      packages."${system}" = import ./packages {
        inherit system pkgs;
      };

      overlay = final: prev: {
        lun = self.packages."${system}";
        powercord-plugins = filterInputs "pcp-";
        powercord-themes = filterInputs "pct-";
      };

      # TODO load automatically with readDir
      nixosConfigurations = {
        lun-kosame-nixos = makeHost pkgs ./hosts/kosame;
        lun-hisame-nixos = makeHost pkgs ./hosts/hisame;
      };

      homeConfigurations =
        let
          homeManagerConfiguration = { configuration, pkgs, extraModules ? [ ], check ? true, extraSpecialArgs ? { } }:
            import "${home-manager}/modules" {
              inherit pkgs check extraSpecialArgs;
              configuration = { ... }: {
                imports = [ configuration ] ++ extraModules;
              };
            };
        in
        {
          lun =
            let username = "lun"; in
            homeManagerConfiguration
              {
                inherit pkgs;
                configuration = {
                  _module.args.pkgs = lib.mkForce pkgs;
                  _module.args.pkgs_i686 = lib.mkForce { };
                  imports = [ ];
                  home.stateVersion = "21.05";
                  home.homeDirectory = "/home/${username}";
                  home.username = "${username}";
                };
              };
        };

      checks."${system}" = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nix-linter.enable = false; # TODO: fix these errors
            nixpkgs-fmt.enable = true;
            shellcheck = {
              enable = true;
              files = "\\.sh$";
              types_or = lib.mkForce [ ];
            };
            shfmt = { };
          };
        };
      };
      devShell.${system} = args.minimal-shell.lib.minimal-shell {
        inherit pkgs system;
        passthru = {
          tempBuildInputs = [ pkgs.nixpkgs-fmt ];
        };
        # TODO handle buildInputs in minimal-shell
        shellHooks = self.checks.${system}.pre-commit-check.shellHook + ''

        for p in $tempBuildInputs; do
          export PATH=$p/bin''${PATH:+:}$PATH
        done
        unset tempBuildInputs;
        '';
      };
    };
}
