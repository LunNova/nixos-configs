{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {

            # ESP partition, or "boot" partition as you may call it. In theory,
            # this config will support VPSes with both EFI and BIOS boot modes.
            ESP = {
              alignment = 2048;
              label = "_esp";
              name = "ESP";
              # Reserve 512MB of space per my own need. If you use more/less
              # on your boot partition, adjust accordingly.
              size = "1024M";
              type = "EF00";
              # Use the second highest priority so it's before the remaining space
              priority = 1;
              # Format as FAT32
              content = {
                type = "filesystem";
                format = "vfat";
                # Use as boot partition. Disko use the information here to mount
                # partitions on disk image generation. Use the same settings as
                # fileSystems.*
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };


            persist = {
              alignment = 2048;
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # disable settings.keyFile if you want to use interactive password entry
                passwordFile = "/tmp/secret.key"; # Interactive
                settings = {
                  allowDiscards = true;
                  #keyFile = "/tmp/secret.key";
                };
                #additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes =
                    let
                      commonOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                      ];
                    in
                    {

                      # nix store
                      "/@nix" = {
                        mountpoint = "/nix";
                        mountOptions = commonOptions;
                      };

                      # Persistent data
                      "/@persist" = {
                        mountpoint = "/persist";
                        mountOptions = commonOptions ++ [
                          "nodev"
                          "nosuid"
                        ];
                      };
                      "/swap" = {
                        mountpoint = "/.swapvol";
                        swap.swapfile.size = "16G";
                      };
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
