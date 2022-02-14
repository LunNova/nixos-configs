{ config, lib, pkgs, ... }:
let
  cfg = config.services.xserver;
  lcfg = config.lun.amd-nvidia-laptop;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
  igpuDriver = "amdgpu"; # try modesetting or intel for intel?
  nvidiaDriver = "nvidia";
  igpuBusId = "PCI:4:0:0";
  nvidiaBusId = "PCI:1:0:0";

  prefixStringLines = prefix: str:
    lib.concatMapStringsSep "\n" (line: prefix + line) (lib.splitString "\n" str);
  indent = prefixStringLines "  ";
in
{
  # see https://download.nvidia.com/XFree86/Linux-x86_64/510.47.03/README/randr14.html
  options.lun.amd-nvidia-laptop = {
    enable = lib.mkEnableOption "Enable amd-nvidia-laptop";
    sync = with lib; mkOption {
      type = with types; bool;
      description = "true for sync 'PRIME', false for offload 'Reverse PRIME'";
      default = true;
    };
    layoutCommand = with lib; mkOption {
      type = with types; nullOr str;
      description = "xrandr layout command after enabling output source. If not set output source won't be enabled";
      default = null;
    };
  };

  config = lib.mkIf lcfg.enable {
    services.xserver.exportConfiguration = true; # Make it easier to look at current x conf in /etc/X11/
    services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
    boot.initrd.kernelModules = [ "amdgpu" "nvidia" "nvidia_drm" "nvidia_modeset" ];
    boot.blacklistedKernelModules = [ "radeon" "nouveau" ];

    # TODO: Remove after https://github.com/NixOS/nixpkgs/pull/153091
    hardware.opengl = {
      package = lib.mkForce pkgs.mesa.drivers;
      package32 = lib.mkForce pkgs.pkgsi686Linux.mesa.drivers;
      # Optionally add amdvlk - IME mesa works better
      extraPackages = [
        pkgs.libglvnd
        (pkgs.hiPrio config.hardware.nvidia.package.out)
      ];
      extraPackages32 = [
        pkgs.pkgsi686Linux.libglvnd
        (pkgs.hiPrio config.hardware.nvidia.package.lib32)
      ];
    };

    # TODO https://forums.developer.nvidia.com/t/bug-nvidia-v495-29-05-driver-spamming-dbus-enabled-applications-with-invalid-messages/192892/14
    # apply patch for nvidia powerd issue?

    # https://wiki.archlinux.org/title/NVIDIA/Troubleshooting#Xorg_fails_during_boot,_but_otherwise_starts_fine
    # TODO: no way to make this a glob? should match number of GPUs
    # TODO: this is deprecated but works and isn't hw specific
    systemd.services.display-manager.wants = [ "systemd-udev-settle.service" ];
    systemd.services.display-manager.after = [ "systemd-udev-settle.service" ];
    systemd.services.display-manager.serviceConfig.ExecStartPre = [ "/bin/sh -c 'sleep 3'" ];
    # systemd.services.display-manager.after = [ "dev-dri-card0.device" "dev-dri-card1.device" ];
    # systemd.services.display-manager.wants = [ "dev-dri-card0.device" "dev-dri-card1.device" ];
    # services.udev.packages = [
    #   (pkgs.writeTextFile {
    #     name = "dri_device_udev";
    #     text = ''
    #       ACTION=="add", KERNEL=="card*", SUBSYSTEM=="drm", TAG+="systemd"
    #     '';

    #     destination = "/etc/udev/rules.d/99-systemd-dri-devices.rules";
    #   })
    # ];

    services.xserver.displayManager.gdm.wayland = lib.mkForce false;

    environment.systemPackages = [ nvidia-offload ];

    # This doesn't conflict with prime any more
    hardware.nvidia.modesetting.enable = true;
    # This doesn't conflict with prime any more
    hardware.nvidia.powerManagement.enable = true;
    #hardware.nvidia.powerManagement.finegrained = true; # Module prevents enabling this without offload but it shouldn't
    services.udev.extraRules = ''
      # Remove NVIDIA Audio devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
      # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
      ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
      # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
      ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
      ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
    '';
    boot.extraModprobeConfig = ''
      options nvidia "NVreg_DynamicPowerManagement=0x02"
      options nvidia-drm modeset=1
    '';
    boot.kernelParams = [ "nvidia-drm.modeset=1" ];

    services.xserver.displayManager.setupCommands =
      let
        igpuProviderName =
          if igpuDriver == "amdgpu" then
          # find the name of the provider if amdgpu
            "`${pkgs.xorg.xrandr}/bin/xrandr --listproviders | ${pkgs.gnugrep}/bin/grep -i AMD | ${pkgs.gnused}/bin/sed -n 's/^.*name://p'`"
          else
            igpuDriver;
        syncEnable = "${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource \"${igpuProviderName}\" NVIDIA-0 || true";
        offloadEnable = "${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource NVIDIA-G0 \"${igpuProviderName}\" || true";
      in
      lib.mkForce (if lcfg.layoutCommand != null then
        (
          (if lcfg.sync then syncEnable else offloadEnable)
          + ''
            # Added by nvidia configuration module for Optimus/PRIME.
            ${pkgs.xorg.xrandr}/bin/xrandr --auto
            ${lcfg.layoutCommand}
          ''
        ) else "");

    services.xserver.config = with lib; mkForce
      ''
        Section "ServerFlags"
          Option "AllowMouseOpenFail" "on"
          Option "DontZap" "${if cfg.enableCtrlAltBackspace then "off" else "on"}"
        ${indent cfg.serverFlagsSection}
        EndSection
        ${optionalString (cfg.moduleSection != "") ''
        Section "Module"
        ${indent cfg.moduleSection}
        EndSection
        ''}
        ${optionalString (cfg.monitorSection != "") ''
          Section "Monitor"
            Identifier "Monitor[0]"
          ${indent cfg.monitorSection}
          EndSection
        ''}
        # Additional "InputClass" sections
        ${flip (concatMapStringsSep "\n") cfg.inputClassSections (inputClassSection: ''
          Section "InputClass"
          ${indent inputClassSection}
          EndSection
        '')}
        Section "ServerLayout"
          Identifier "Layout[all]"
        ${indent cfg.serverLayoutSection}
        EndSection
        ${if cfg.useGlamor then ''
          Section "Module"
            Load "dri2"
            Load "glamoregl"
          EndSection
        '' else ""}
        # For each supported driver, add a "Device" and "Screen"
        # section.
        ${flip concatMapStrings cfg.drivers (driver: ''
          Section "Device"
            Identifier "Device-${driver.name}[0]"
            Driver "${driver.driverName or driver.name}"
            ${if cfg.useGlamor then ''Option "AccelMethod" "glamor"'' else ""}
          ${indent cfg.deviceSection}
          ${indent (driver.deviceSection or "")}
          EndSection
          ${optionalString driver.display ''
            Section "Screen"
              Identifier "Screen-${driver.name}[0]"
              Device "Device-${driver.name}[0]"
              ${optionalString (cfg.monitorSection != "") ''
                Monitor "Monitor[0]"
              ''}
            ${indent cfg.screenSection}
            ${indent (driver.screenSection or "")}
              ${optionalString (cfg.defaultDepth != 0) ''
                DefaultDepth ${toString cfg.defaultDepth}
              ''}
              ${optionalString
                (
                  driver.name != "virtualbox"
                  &&
                  (cfg.resolutions != [] ||
                    cfg.extraDisplaySettings != "" ||
                    cfg.virtualScreen != null
                  )
                )
                (let
                  f = depth:
                    ''
                      SubSection "Display"
                        Depth ${toString depth}
                        ${optionalString (cfg.resolutions != [])
                          "Modes ${concatMapStrings (res: ''"${toString res.x}x${toString res.y}"'') cfg.resolutions}"}
                      ${indent cfg.extraDisplaySettings}
                        ${optionalString (cfg.virtualScreen != null)
                          "Virtual ${toString cfg.virtualScreen.x} ${toString cfg.virtualScreen.y}"}
                      EndSubSection
                    '';
                in concatMapStrings f [8 16 24]
              )}
            EndSection
          ''}
        '')}
        ${cfg.extraConfig}
      '';

    services.xserver.drivers = lib.mkForce [
      {
        name = igpuDriver;
        display = true;
        modules = lib.optional (igpuDriver == "amdgpu") pkgs.xorg.xf86videoamdgpu;
        deviceSection = ''
          BusID "${igpuBusId}"
        '';
      }
      {
        name = "nvidia";
        modules = [ config.hardware.nvidia.package.bin ];
        display = true;
        deviceSection =
          ''
            BusID "${nvidiaBusId}"
            Option "AllowExternalGpus"
          '';
        screenSection =
          ''
            Option "RandRRotation" "on"
          '' + (lib.optionalString (lcfg.sync) ''
            Option "AllowEmptyInitialConfiguration"
          '');
      }
    ];

    services.xserver.serverLayoutSection = lib.mkForce (
      ''
        Inactive "Device-${if lcfg.sync then igpuDriver else nvidiaDriver}[0]"
        Screen 0 "Screen-${if !lcfg.sync then igpuDriver else nvidiaDriver}[0]"
      ''
      + (lib.optionalString lcfg.sync ''
        Option "MetaModes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
      '')
      + (lib.optionalString (!lcfg.sync) ''
        Option "AllowNVIDIAGPUScreens"
      '')
    );
  };
}
