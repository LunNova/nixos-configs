{
  description = "lun's system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-22.05";
    nixpkgs-cura-testing.url = "github:LunNova/nixpkgs/bd7de0e7c17a16885fbe25ffb7c266fffb65dfb9";
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
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    oxalica-nil.url = "github:oxalica/nil";
    oxalica-nil.inputs.rust-overlay.follows = "rust-overlay";
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
    openxr-nix-flake.url = "github:LunNova/openxr-nix-flake";
    openxr-nix-flake.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    background-switcher.url = "github:bootstrap-prime/background-switcher";
    background-switcher.inputs.nixpkgs.follows = "nixpkgs";
    background-switcher.inputs.flake-utils.follows = "flake-utils";
    background-switcher.inputs.rust-overlay.follows = "rust-overlay";
    mobile-nixos = {
      url = "github:NixOS/mobile-nixos";
      flake = false;
    };
    plover-flake = {
      url = "github:dnaq/plover-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    minimal-shell.url = "github:LunNova/nix-minimal-shell";

    # Powercord. pcp- and pct- prefix have meaning, cause inclusion as powercord plugin/theme
    replugged-nix-flake = {
      url = "github:LunNova/replugged-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TODO: check for web access loading scripts and patch out
    # pcp-tweaks = { url = "github:NurMarvin/discord-tweaks"; flake = false; };
    # pcp-theme-toggler = { url = "github:redstonekasi/theme-toggler"; flake = false; };
    #Doesn't work on electron 15
    # pcp-better-status-indicators = { url = "github:GriefMoDz/better-status-indicators"; flake = false; };
    # pcp-webhook-tag = { url = "github:BenSegal855/webhook-tag"; flake = false; };
    # pcp-always-push = { url = "github:Karamu98/AlwaysPushNotifications"; flake = false; };
    # TODO: locked version of this which doesn't hit web
    # pct-clearvision = { url = "github:ClearVision/ClearVision-v6"; flake = false; };
    # pcp-hidden = { url = "github:discord-modifications/show-hidden-channels"; flake = false; };
    # TODO: background overrides here instead of manually configured?
  };

  # SCHEMA:
  # lib                       = nix library functions, work on any system
  # nixosConfigurations       = attrset with nixosConfigurations by hostname, each host is for one specific system
  # overlay                   = function that can be used as a nixpkgs overlay, hopefully works on any system
  # perSystem                 = function which takes system as input and generates system specific outputs for that system
  #                             (system: { packages, legacyPackages, homeConfigurations, checks, slowChecks })
  # packages.system           = attrset with packages marked as able to eval/build, generated by perSystem
  # legacyPackages.system     = attrset with packages including unsupported/marked broken, generated by perSystem
  # homeConfigurations.system = attrset with homeConfigurations by username, generated by perSystem
  # checks.system             = attrset with checks, generated by perSystem
  # slowChecks.system         = attrset with checks that are too slow for nix flake check but are used in CI, generated by perSystem
  outputs = flakeArgs:
    let
      perSystem = import ./per-system.nix { inherit flakeArgs; };
      serviceTest = import ./service-test.nix { };
      inherit (flakeArgs) self;
    in
    {
      inherit flakeArgs perSystem;

      lib = import ./lib { bootstrapLib = flakeArgs.nixpkgs.lib; };
      assets = import ./assets;
      overlays.default = import ./overlay.nix { inherit flakeArgs; };
      overlay = self.overlays.default; # deprecated alias, TODO: remove in 2023
      localPackagesForPkgs = pkgs: import ./packages { inherit pkgs flakeArgs; };
      nixosModules = self.lib.readExportedModules ./modules/exported;

      nixosConfigurations =
        let
          linux64 = perSystem "x86_64-linux";
          linuxaarch64 = perSystem "aarch64-linux";
        in
        {
          test-vm = linux64.makeHost ./hosts/test-vm;
          router-nixos = linux64.makeHost ./hosts/router;
          lun-kosame-nixos = linux64.makeHost ./hosts/kosame;
          lun-hisame-nixos = linux64.makeHost ./hosts/hisame;
          lun-amayadori-nixos = linuxaarch64.makeHost ./hosts/amayadori;
          mmk-raikiri-nixos = linux64.makeHost ./hosts/raikiri;
        };

      deploy.nodes.router = {
        hostname = "10.5.5.1"; # "router-nixos";
        profiles.system = {
          sshUser = "lun";
          user = "root";
          path = flakeArgs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router-nixos;
        };
      };
      deploy.nodes.testSingleServiceDeployAsLunOnLocalhost = {
        hostname = "localhost";
        profiles.serviceTest = serviceTest.hmProfile {
          inherit (flakeArgs) deploy-rs;
          inherit (flakeArgs.nixpkgs) lib;
          inherit (flakeArgs.self.homeConfigurations.x86_64-linux.lun) pkgs;
          user = "lun";
          modules = [
            serviceTest.helloWorldModule
          ];
          hm = import "${flakeArgs.home-manager}/modules";
        };
      };
    } // flakeArgs.flake-utils.lib.eachDefaultSystem perSystem;
}
