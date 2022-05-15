{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-21.11";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    minimal-shell.url = "github:LunNova/nix-minimal-shell";

    # Powercord. pcp- and pct- prefix have meaning, cause inclusion as powercord plugin/theme
    powercord = { url = "github:powercord-org/powercord"; flake = false; };
    powercord-overlay = {
      # TODO: drop hash after handles license header change
      url = "github:LavaDesu/powercord-overlay/70610a69c37a9bedfd498cd8848a052c14d1c12e";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.powercord.follows = "powercord";
    };
    # TODO: check for web access loading scripts and patch out
    pcp-tweaks = { url = "github:NurMarvin/discord-tweaks"; flake = false; };
    pcp-theme-toggler = { url = "github:redstonekasi/theme-toggler"; flake = false; };
    #Doesn't work on electron 15
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
      lib = pkgs.lib.extend (final: prev:
        let self = args.nixpkgs; in
        {
          nixosSystem = args:
            import "${pkgs}/nixos/lib/eval-config.nix" (args // {
              modules = args.modules ++ [{
                system.nixos.versionSuffix =
                  ".${final.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}.${self.shortRev or "dirty"}";
                system.nixos.revision = final.mkIf (self ? rev) self.rev;
              }];
            });
        });
      lunLib = import ./lib { bootstrapLib = args.nixpkgs.lib; };
      system = "x86_64-linux";

      pkgsPatches = let legacyPackages = nixpkgs.legacyPackages.${system}; in
        [
          (legacyPackages.fetchpatch {
            # steam fixes https://github.com/NixOS/nixpkgs/pull/157907/commits
            url = "https://github.com/NixOS/nixpkgs/compare/d536e0a0eb54ea51c676869991fe5a1681cc6302.patch";
            sha256 = "sha256-aKUt0iJp3TX3bzkxyWM/Pt61l9HnsnKGD2tX24H3dAA=";
          })
        ];
      defaultPkgsConfig = {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # (final: prev: {
          #   some-package = ...
          # })
          self.overlay
          powercord-overlay.overlay
        ];
      };

      pkgs = lunLib.mkPkgs args.nixpkgs system pkgsPatches defaultPkgsConfig;
      pkgs-stable = lunLib.mkPkgs args.nixpkgs-stable system [ ] defaultPkgsConfig;
      readModules = path: builtins.map (x: path + "/${x}") (builtins.filter (str: (builtins.match "^[^.]*(\.nix)?$" str) != null) (builtins.attrNames (builtins.readDir path)));
      readExportedModules = path: lib.mapAttrs'
        (key: value:
          lib.nameValuePair
            (lib.removeSuffix ".nix" key)
            ({ pkgs, ... }@args: import (path + "/${key}") (args // {
              pkgs = args.pkgs // { lun = args.pkgs.lun or (localPackagesForPkgs args.pkgs); };
            })))
        (builtins.readDir path);
      makeHost = pkgs: path: lib.nixosSystem {
        inherit system;

        specialArgs =
          {
            inherit pkgs-stable;
            flake-args = args;
            lun = args.self;
            nixos-hardware-modules-path = "${args.nixos-hardware}";
          };

        modules = [
          { nixpkgs.pkgs = pkgs; }
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
        ]
        ++ (builtins.attrValues self.nixosModules)
        ++ (readModules ./modules);
      };
      localPackagesProto = import ./packages;
      localPackagesForPkgs = pkgs: localPackagesProto {
        inherit pkgs;
        flake-args = args;
      };
      localPackages = localPackagesForPkgs pkgs;
      enableKwinFt = false;
    in
    {
      inherit args;

      inputs = args;

      inherit pkgs;

      lib = lunLib;

      packages."${system}" = lib.filterAttrs (k: lib.isDerivation) localPackages;

      overlay = final: prev:
        let localPackages = localPackagesForPkgs final;
        in
        {
          lun = localPackages;
          powercord-plugins = lunLib.filterPrefix "pcp-" args;
          powercord-themes = lunLib.filterPrefix "pct-" args;
          inherit (localPackages) kwinft;
          # gst-plugins-bad pulls in opencv which we don't want
          # TODO: upstream option for this
          # gst_all_1 = (prev.gst_all_1 // {
          #   gst-plugins-bad = (prev.gst_all_1.gst-plugins-bad.override {
          #     opencv4 = prev.emptyDirectory;
          #   }).overrideAttrs
          #     (prev: {
          #       mesonFlags = prev.mesonFlags ++ [ "-Dopencv=disabled" ];
          #     });
          # });
        } // (lunLib.setIf enableKwinFt {
          plasma5Packages = prev.plasma5Packages.overrideScope' (self2: super2: {
            plasma5 = super2.plasma5.overrideScope' (self1: super1: {
              inherit (localPackages.kwinft) kwin;
              inherit (prev.plasma5Packages.plasma5) plasma-workspace;
            });
          });
        });

      nixosModules = readExportedModules ./modules/exported;

      nixosConfigurations = {
        lun-kosame-nixos = makeHost pkgs ./hosts/kosame;
        lun-hisame-nixos = makeHost pkgs ./hosts/hisame;
        mmk-raikiri-nixos = makeHost pkgs ./hosts/raikiri;
      };

      assets = import ./assets;

      homeConfigurations =
        let makeUser = username:
          import "${home-manager}/modules" {
            inherit pkgs;
            check = true;
            extraSpecialArgs = {
              inherit pkgs-stable;
              nixosConfig = null;
              lun = args.self;
            };
            configuration = {
              _module.args.pkgs = lib.mkForce pkgs;
              _module.args.pkgs_i686 = lib.mkForce { };
              imports = [ "${./users}/${username}" ];
              home.homeDirectory = "/home/${username}";
              home.username = "${username}";
            };
          }; in
        {
          lun = makeUser "lun";
          mmk = makeUser "mmk";
        };

      checks."${system}" = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            statix.enable = true;
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
      slowChecks.${system} = rec {
        all-packages = pkgs.symlinkJoin {
          name = "lun self.packages ${system}";
          paths = lib.attrValues self.packages.${system};
        };
        all-systems = pkgs.symlinkJoin {
          name = "lun self.nixosConfigurations";
          paths = map (cfg: self.nixosConfigurations.${cfg}.config.system.build.toplevel) (builtins.attrNames self.nixosConfigurations);
        };
        all-users = pkgs.symlinkJoin {
          name = "lun self.homeConfigurations";
          paths = map (cfg: self.homeConfigurations.${cfg}.activationPackage) (builtins.attrNames self.homeConfigurations);
        };
        all = pkgs.symlinkJoin {
          name = "lun all";
          paths = [ all-packages all-systems all-users ];
        };
      };
      devShell.${system} = args.minimal-shell.lib.minimal-shell {
        inherit pkgs system;
        passthru = {
          nativeBuildInputs = [ pkgs.nixpkgs-fmt ];
        };
        # TODO handle buildInputs in minimal-shell
        shellHooks = self.checks.${system}.pre-commit-check.shellHook;
      };
    };
}
