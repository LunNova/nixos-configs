{ config, pkgs, lib, ... }:

# borrowed some stuff from https://github.com/georgewhewell/nixos-host/blob/master/profiles/router.nix
# also begyn.be https://francis.begyn.be/blog/ipv6-nixos-router
# also https://github.com/skogsbrus/os/blob/406df9a6e38a805fdae8e683fe43b5a6c320b2ec/sys/router.nix https://skogsbrus.xyz/blog/2022/06/12/router/
let
  name = "router";
  lanInterface = "eno1";
  wanInterface = "enp2s0f1";
  debugInterface = "enp2s0f2";
  lanV4Subnet = "10.5.5";
  lanV4Self = "${lanV4Subnet}.1";
  fullHostName = "${config.networking.hostName}.${config.networking.domain}";
  btrfsOpts = [ "rw" "noatime" "compress=zstd" "space_cache=v2" "noatime" "autodefrag" ];
  btrfsSsdOpts = btrfsOpts ++ [ "ssd" "discard=async" ];
  # cloudVPNInterface = "wg0-cloud";
  # swapsVPNInterface = "wg1-swaps";
  # vpnInterfaces = [ ];
  #lanBridge = "br0.lan";
in
{
  imports = [
  ];

  config = {
    sconfig.machineId = "62df49c6dd7668e60028ed7c7f8b009d";
    system.stateVersion = "22.11";

    boot.kernelParams = [ ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    boot.initrd.kernelModules = [ ];

    # lib.mkForce is important here, want to make sure service modules
    # don't open ports to the outside world
    networking = lib.mkForce {
      hostName = "${name}-nixos";
      domain = "home.moonstruck.dev";
      useDHCP = false;
      nameservers = [
        # quad9
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
        # cloudflare
        "1.1.1.1"
        "1.0.0.1"
        # google
        "8.8.8.8"
        "8.8.4.4"
      ];
      useNetworkd = true;
      extraHosts = ''
        ${lanV4Self} ${fullHostName}
      '';
      firewall = {
        enable = true;
        trustedInterfaces = [ lanInterface debugInterface ];
      };
      # not sure whether to use a bridge
      # bridges."${lanBridge}" = {
      #   interfaces = [
      #     lanInterface
      #   ];
      # };  
    };
    lun.profiles = {
      server = true;
      gaming = false;
      graphical = false;
    };
    services.resolved.enable = false;
    systemd.network = {
      networks = {
        "wan" = {
          name = wanInterface;
          networkConfig = {
            DHCP = "yes";
            Description = "ISP interface";
            IPv6AcceptRA = true;
          };
          linkConfig = {
            RequiredForOnline = "routable";
          };
          dhcpV6Config = {
            PrefixDelegationHint = "::/48";
          };
          ipv6PrefixDelegationConfig = {
            Managed = true;
          };
        };
        "dbg" = {
          name = debugInterface;
          networkConfig = {
            DHCP = "yes";
            IPv6AcceptRA = true;
          };
        };
        "lan" = {
          name = lanInterface;
          networkConfig = {
            DHCP = "no";
            Description = "LAN interface";
            # the client shouldn't be allowed to send us RAs, that would be weird.
            IPv6AcceptRA = false;
            IPv6SendRA = true;

            # Just delegate prefixes from the DHCPv6 PD pool.
            # If you also want to distribute a local ULA prefix you want to
            # set this to `yes` as that includes both static prefixes as well
            # as PD prefixes.
            DHCPPrefixDelegation = "yes";
          };
          # finally "act as router" (according to systemd.network(5))
          # ipv6PrefixDelegationConfig = {
          #   RouterLifetimeSec = 300; # required as otherwise no RA's are being emitted

          #   # In a production environment you should consider setting these as well:
          #   EmitDNS = true;
          #   EmitDomains = true;
          #   DNS = "fe80::1"; # or whatever "well known" IP your router will have on the inside.
          # };

          # Add ULA prefix
          ipv6Prefixes = [
            {
              ipv6PrefixConfig = {
                Prefix = "fd79:fc8d:af3a:ad8b::/64";
                AddressAutoconfiguration = true;
                PreferredLifetimeSec = 1800;
                ValidLifetimeSec = 1800;
              };
            }
          ];
        };
      };
    };
    # dnsmasq handles dhcp and dns
    services.dnsmasq = {
      enable = true;
      extraConfig = ''
        # sensible behaviours
        domain-needed
        bogus-priv
        no-resolv
        # upstream name servers
        server=9.9.9.9
        server=1.1.1.1
        # local domains
        expand-hosts
        domain=${config.networking.domain}
        local=/${config.networking.domain}/
        local=/local/
        # Interfaces to serve on
        # can repeat this line for multiple interfaces
        interface=${lanInterface}
        # subnet IP blocks to use DHCP on, repeat line for multiple
        dhcp-range=${lanV4Subnet}.50,${lanV4Subnet}.254,24h
        # static IP example
        # dhcp-host=00:0d:b9:5e:22:91,$ {private_subnet}.1
      '';
    };
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;

      # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
      # By default, not automatically configure any IPv6 addresses.
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;

      # On WAN, allow IPv6 autoconfiguration and tempory address use.
      "net.ipv6.conf.${wanInterface}.accept_ra" = 2;
      "net.ipv6.conf.${wanInterface}.autoconf" = 1;
      "net.ipv6.conf.${debugInterface}.accept_ra" = 2;
      "net.ipv6.conf.${debugInterface}.autoconf" = 1;
    };
    services.corerad = {
      enable = true;
      settings = {
        debug = {
          address = "localhost:9430";
          prometheus = true; # enable prometheus metrics
        };
        interfaces = [
          {
            name = "ppp0";
            monitor = false; # see the remark below
          }
          {
            name = lanInterface;
            advertise = true;
            prefix = [
              { prefix = "::/64"; }
            ];
          }
        ];
      };
    };
    services.miniupnpd = {
      enable = true;
      externalInterface = wanInterface;
      internalIPs = [ lanInterface ];
      natpmp = true;
      upnp = true;
    };
    services.avahi = lib.mkForce {
      enable = true;
      interfaces = [ lanInterface ];
      ipv4 = true;
      ipv6 = true;
      reflector = true;
    };
    # https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
    services.grafana = {
      enable = true;
      port = 8888;
      addr = "0.0.0.0"; # FIXME: one interface only?
      dataDir = "/var/lib/grafana";
    };
    lun.persistence.dirs = [ "/var/lib/grafana" "/var/tmp" "/tmp" ];

    services.lldpd.enable = true;

    boot.kernelModules = [ "tcp_bbr" ];
    boot.kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = lib.mkForce "bbr"; # apparently this works for ipv6 too
      "net.core.default_qdisc" = lib.mkForce "fq_codel"; # FIXME doesn't apply to all nics, set too late in boot?
    };

    hardware.cpu.amd.updateMicrocode = true;

    users.mutableUsers = false;

    lun.persistence.enable = true;
    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "defaults" "size=2G" "mode=755" ];
      };
      "/boot" = {
        device = "/dev/disk/by-partlabel/${name}_esp";
        fsType = "vfat";
        neededForBoot = true;
        options = [ "discard" "noatime" ];
      };
      "/persist" = {
        device = "/dev/disk/by-partlabel/${name}_persist";
        fsType = "btrfs";
        neededForBoot = true;
        options = btrfsSsdOpts ++ [ "subvol=@persist" "nodev" "nosuid" ];
      };
      "/nix" = {
        neededForBoot = true;
      };
    };
    swapDevices = [ ];
  };
}
