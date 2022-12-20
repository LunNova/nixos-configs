{ flake-args }:
system:
let
  pkgsPatches = [
    # add .patch to a github PR URL to get a patch quickly
    ./nixpkgs-patches/lutris-xdg-data-dirs.patch
  ];
  defaultPkgsConfig = {
    config.allowUnfree = true;
    overlays = [
      # (final: prev: {
      #   some-package = ...
      # })
      flake-args.self.overlay
    ];
  };
  readModules = path: builtins.map (x: path + "/${x}") (builtins.filter (str: (builtins.match "^[^.]*(\.nix)?$" str) != null) (builtins.attrNames (builtins.readDir path)));
  lib = perSystemSelf.nixpkgsLib;
  perSystemSelf = {
    # hack: only patch for x86_64 so nix flake check doesn't fall over for other platforms
    # eventually will get rid of this IFD
    # once there's patches support for flake inputs
    # https://github.com/NixOS/nix/pull/6530
    pkgs = flake-args.self.lib.mkPkgs flake-args.nixpkgs system (if system == "x86_64-linux" then pkgsPatches else [ ]) (defaultPkgsConfig // { inherit system; });
    pkgs-stable = flake-args.self.lib.mkPkgs flake-args.nixpkgs-stable system [ ] (defaultPkgsConfig // { inherit system; });
    nixpkgsLib = flake-args.nixpkgs.lib.extend (final: _prev: {
      nixosSystem = args:
        import "${flake-args.nixpkgs}/nixos/lib/eval-config.nix" (args // {
          modules = args.modules ++ [{
            system.nixos.versionSuffix = "";
            system.nixos.revision = "";
          }];
        });

    });
    makeHost = path: lib.nixosSystem {
      inherit (perSystemSelf.pkgs) system;

      specialArgs =
        {
          inherit flake-args;
          inherit (perSystemSelf) pkgs-stable;
          nixos-hardware-modules-path = "${flake-args.nixos-hardware}";
        };

      modules = [
        { nixpkgs.pkgs = perSystemSelf.pkgs; }
        flake-args.home-manager.nixosModules.home-manager
        flake-args.nix-gaming.nixosModules.pipewireLowLatency
        path
        ./users
        ({ config, ... }:
          {
            config = {
              home-manager.extraSpecialArgs = {
                inherit flake-args;
                inherit (perSystemSelf) pkgs-stable;
                lun-profiles = config.lun.profiles;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            };
          })
      ]
      ++ (builtins.attrValues flake-args.self.nixosModules)
      ++ (readModules ./modules);
    };
    legacyPackages = flake-args.self.localPackagesForPkgs perSystemSelf.pkgs;
    packages = lib.filterAttrs (_k: pkg: lib.isDerivation pkg && !((pkg.meta or { }).broken or false) && (!(pkg ? meta && pkg.meta ? platforms) || builtins.elem system pkg.meta.platforms)) perSystemSelf.legacyPackages;
    devShell = flake-args.minimal-shell.lib.minimal-shell {
      inherit system;
      inherit (perSystemSelf) pkgs;
      passthru = {
        nativeBuildInputs = [ perSystemSelf.pkgs.nixpkgs-fmt ];
      };
      # TODO handle buildInputs in minimal-shell
      shellHooks = perSystemSelf.checks.pre-commit-check.shellHook;
    };
    formatter = perSystemSelf.pkgs.nixpkgs-fmt;

    homeConfigurations =
      let
        makeUser = username:
          import "${flake-args.home-manager}/modules" {
            inherit (perSystemSelf) pkgs;
            check = true;
            extraSpecialArgs = {
              inherit flake-args;
              inherit (perSystemSelf) pkgs-stable;
              nixosConfig = null;
              lun-profiles = {
                graphical = true;
              };
            };
            configuration = {
              _module.args.pkgs = lib.mkForce perSystemSelf.pkgs;
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
    slowChecks = rec {
      all-packages = perSystemSelf.pkgs.symlinkJoin {
        name = "lun packages.${system}";
        paths = lib.attrValues perSystemSelf.packages;
      };
      all-systems = perSystemSelf.pkgs.symlinkJoin {
        name = "lun nixosConfigurations for system ${system}";
        paths = lib.filter (x: x.system == system) (map (cfg: flake-args.self.nixosConfigurations.${cfg}.config.system.build.toplevel) (builtins.attrNames flake-args.self.nixosConfigurations));
      };
      all-users = perSystemSelf.pkgs.symlinkJoin {
        name = "lun homeConfigurations for system ${system}";
        paths = map (x: x.activationPackage) (lib.attrValues perSystemSelf.homeConfigurations);
      };
      all = perSystemSelf.pkgs.symlinkJoin {
        name = "lun all";
        paths = [ all-packages all-systems all-users ];
      };
    };
    checks = {
      pre-commit-check = flake-args.pre-commit-hooks.lib.${system}.run {
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
    } // flake-args.deploy-rs.lib.${system}.deployChecks flake-args.self.deploy;
  };
in
perSystemSelf
