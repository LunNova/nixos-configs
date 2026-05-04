{ config, ... }:
{
  boot.initrd.systemd.enable = true;

  # nix build .#nixosConfigurations.kirisame-nixos.config.system.build.diskoImages
  disko = {
    enableConfig = false;
    memSize = 4096;

    devices.nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "relatime" "mode=755" "nosuid" "nodev" ];
    };
    devices.disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        imageName = "nixos-${config.networking.hostName}";
        imageSize = "8G";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              alignment = 2048;
              label = "kirisame_esp";
              name = "ESP";
              size = "512M";
              type = "EF00";
              priority = 1;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };

            persist = {
              alignment = 2048;
              size = "100%";
              label = "kirisame_persist";
              content = {
                type = "btrfs";
                subvolumes =
                  let
                    commonOptions = [
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                    ];
                  in
                  {
                    "/@nix" = {
                      mountpoint = "/nix";
                      mountOptions = commonOptions;
                    };
                    "/@persist" = {
                      mountpoint = "/persist";
                      mountOptions = commonOptions ++ [
                        "nodev"
                        "nosuid"
                      ];
                    };
                  };
              };
            };
          };
        };
      };
    };
  };
}
