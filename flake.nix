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
      mkPkgs = pkgs: extraOverlays:
        import pkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = extraOverlays;
        };
      filterInputs = prefix: builtins.attrValues (lib.filterAttrs (name: value: (lib.hasPrefix prefix name)) args);
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

      pkgs = mkPkgs args.nixpkgs [ self.overlay powercord-overlay.overlay ];
      lib = args.nixpkgs.lib;
      readModules = path: builtins.map (x: path + "/${x}") (builtins.attrNames (builtins.readDir path));
      makeHost = path: lib.nixosSystem {
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
            nix.registry.nixpkgs.flake = nixpkgs-unfree-relocked;
            nix.nixPath = [ "nixpkgs=${nixpkgs-unfree-relocked}" ];
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

      packages."${system}" = {
        key-mapper = pkgs.callPackage packages/key-mapper { };
      };

      overlay = final: prev: {
        my = self.packages."${system}";
        powercord-plugins = filterInputs "pcp-";
        powercord-themes = filterInputs "pct-";
      };

      # TODO load automatically with readDir
      nixosConfigurations = {
        lun-kosame-nixos = makeHost ./hosts/kosame;
        lun-hisame-nixos = makeHost ./hosts/hisame;
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
        shellHooks = self.checks.${system}.pre-commit-check.shellHook;
      };
    };
}
