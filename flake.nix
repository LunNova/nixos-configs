{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-mesa-pr.url = "github:NixOS/nixpkgs/837bdeb0251fe30e85ebbd66db20ffb6c66083e3";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-22.05";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    erosanix.url = "github:emmanuelrosa/erosanix";
    erosanix.inputs.nixpkgs.follows = "nixpkgs";
    oxalica-nil.url = "github:oxalica/nil";
    oxalica-nil.inputs.nixpkgs.follows = "nixpkgs";
    oxalica-nil.inputs.flake-utils.follows = "flake-utils";
    thoth-reminder-bot.url = "github:mmk150/reminder_bot";
    thoth-reminder-bot.inputs.nixpkgs.follows = "nixpkgs";
    thoth-reminder-bot.inputs.flake-utils.follows = "flake-utils";
    nixpkgs-review-checks.url = "github:SuperSandro2000/nixpkgs-review-checks";
    nixpkgs-review-checks.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-review-checks.inputs.flake-utils.follows = "flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    linux-freedesktop-drm-misc-fixes = {
      url = "github:freedesktop/drm-misc/drm-misc-fixes";
      flake = false;
    };

    minimal-shell.url = "github:LunNova/nix-minimal-shell";

    # Powercord. pcp- and pct- prefix have meaning, cause inclusion as powercord plugin/theme
    replugged = { url = "github:replugged-org/replugged"; flake = false; };
    replugged-nix-flake = {
      url = "github:LunNova/replugged-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.replugged.follows = "replugged";
    };
    # TODO: check for web access loading scripts and patch out
    # pcp-tweaks = { url = "github:NurMarvin/discord-tweaks"; flake = false; };
    # pcp-theme-toggler = { url = "github:redstonekasi/theme-toggler"; flake = false; };
    #Doesn't work on electron 15
    # pcp-better-status-indicators = { url = "github:GriefMoDz/better-status-indicators"; flake = false; };
    pcp-webhook-tag = { url = "github:BenSegal855/webhook-tag"; flake = false; };
    pcp-always-push = { url = "github:Karamu98/AlwaysPushNotifications"; flake = false; };
    # TODO: locked version of this which doesn't hit web
    pct-clearvision = { url = "github:ClearVision/ClearVision-v6"; flake = false; };
    # pcp-hidden = { url = "github:discord-modifications/show-hidden-channels"; flake = false; };
    # TODO: background overrides here instead of manually configured?
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , pre-commit-hooks
    , nix-gaming
    , ...
    }@args:
    let
      lib = pkgs.lib.extend (final: _prev:
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

      pkgsPatches =
        [
          # (nixpkgs.legacyPackages.${system}.fetchpatch {
          #   # steam fixes https://github.com/NixOS/nixpkgs/pull/157907/commits
          #   url = "https://github.com/NixOS/nixpkgs/compare/d536e0a0eb54ea51c676869991fe5a1681cc6302.patch";
          #   sha256 = "sha256-aKUt0iJp3TX3bzkxyWM/Pt61l9HnsnKGD2tX24H3dAA=";
          # })
          (nixpkgs.legacyPackages.${system}.fetchpatch {
            #  xdg-utils,nixos/xdg/portal: implement workaround for opening programs from FHS envs or wrappers reliably #197118 
            url = "https://github.com/NixOS/nixpkgs/compare/staging..856566f3654381a75aade0e2f3d5ceb8b5e9617e.patch";
            sha256 = "sha256-rUIhVB1RQXkOk+0Hhhui9ZJ/KGMxIzuWn9cZP80QbBE=";
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
        ];
      };

      pkgs = lunLib.mkPkgs args.nixpkgs system pkgsPatches defaultPkgsConfig;
      pkgs-stable = lunLib.mkPkgs args.nixpkgs-stable system [ ] defaultPkgsConfig;
      readModules = path: builtins.map (x: path + "/${x}") (builtins.filter (str: (builtins.match "^[^.]*(\.nix)?$" str) != null) (builtins.attrNames (builtins.readDir path)));
      readExportedModules = path: lib.mapAttrs'
        (key: _value:
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
          ({ config, ... }:
            {
              config = {
                home-manager.extraSpecialArgs = {
                  lun = args.self;
                  flake-args = args;
                  lun-profiles = config.lun.profiles;
                };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              };
            })
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

      packages."${system}" = lib.filterAttrs (_k: lib.isDerivation) localPackages;

      overlay = final: prev:
        let localPackages = localPackagesForPkgs final;
        in
        {
          lun = localPackages;
          powercord-plugins = lunLib.filterPrefix "pcp-" args;
          powercord-themes = lunLib.filterPrefix "pct-" args;
          inherit (localPackages) kwinft;
          nix-gaming = args.nix-gaming.packages.${final.system};
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
          plasma5Packages = prev.plasma5Packages.overrideScope' (_self2: super2: {
            plasma5 = super2.plasma5.overrideScope' (_self1: _super1: {
              inherit (localPackages.kwinft) kwin;
              inherit (prev.plasma5Packages.plasma5) plasma-workspace;
            });
          });
          # TODO: can we get disman and kdisplay included just with this toggle
        });

      nixosModules = readExportedModules ./modules/exported;

      nixosConfigurations = {
        router-nixos = makeHost pkgs ./hosts/router;
        lun-kosame-nixos = makeHost pkgs ./hosts/kosame;
        lun-hisame-nixos = makeHost pkgs ./hosts/hisame;
        mmk-raikiri-nixos = makeHost pkgs ./hosts/raikiri;
      };

      assets = import ./assets;

      homeConfigurations =
        let
          makeUser = username:
            import "${home-manager}/modules" {
              inherit pkgs;
              check = true;
              extraSpecialArgs = {
                inherit pkgs-stable;
                nixosConfig = null;
                lun-profiles = {
                  graphical = true;
                };
                lun = args.self;
                flake-args = args;
              };
              configuration = {
                _module.args.pkgs = lib.mkForce pkgs;
                _module.args.pkgs_i686 = lib.mkForce { };
                imports = [ "${./users}/${username}" ];
                home.homeDirectory = "/home/${username}";
                home.username = "${username}";
              };
            };
        in
        {
          lun = makeUser "lun";
          mmk = makeUser "mmk";
        };

      deploy.nodes.router = {
        hostname = "10.5.5.1"; # "router-nixos";
        profiles.system = {
          sshUser = "lun";
          user = "root";
          path = args.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router-nixos;
        };
      };

      checks = lunLib.recursiveMerge [
        {
          "${system}" = {
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
                shfmt = {
                  enable = true;
                  files = "\\.sh$";
                };
              };
            };
          };
        }
        (builtins.mapAttrs
          (system: deployLib: deployLib.deployChecks self.deploy)
          args.deploy-rs.lib)
      ];

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
