{ self, inputs, ... }:
{
  flake.nixosModules.homelab =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {

      imports = [
        self.nixosModules.homelabHardwareConfiguration
        self.nixosModules.homelabDiskoConfiguration
        self.nixosModules.impermanence
        self.nixosModules.serverTemplate
        self.nixosModules.keanu
      ];

      features.telemetry.role = "client";

      # For some reason the homelab host doesn't like systemd-boot which is provided by the serverTemplate module
      # We force it to use grub here
      # TODO: Figure out why this is the case and remove the need for forcing a different boot loader configuration on a server
      boot.loader.grub = {
        enable = lib.mkForce true;
        configurationLimit = 10;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
      boot.loader.systemd-boot.enable = lib.mkForce false;

      impermanence = {
        enable = false;
        rootDevice = "/dev/disk/by-partlabel/disk-main-root";
        rootDeviceUnit = "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device";
      };

      networking = {
        hostName = "homelab";
        defaultGateway = {
          address = "192.168.1.1";
          interface = "eno1";
        };
        useNetworkd = true;
        firewall.allowedTCPPorts = [
          5201 # iperf3
        ];
        interfaces = {
          eno1 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.7";
                prefixLength = 24;
              }
            ];
          };
        };
      };

      systemd.network = {
        enable = true;
        networks = {
          "40-eno1" = {
            enable = true;
            name = "eno1";
            gateway = [ "192.168.1.1" ];
            address = [ "192.168.1.7" ];
            routes = [
              {
                Gateway = "192.168.1.1";
              }
            ];
            matchConfig = {
              Name = "eno1";
              Host = "homelab";
              MACAddress = "6c:0b:84:e2:82:4b";
            };
            networkConfig = {
              DHCP = "no";
              IPv6PrivacyExtensions = "kernel";
            };
            linkConfig.RequiredForOnline = "routable";
          };
        };
      };

      boot.kernel.sysctl = {
        "net.core.rmem_max" = 67108864;
        "net.core.wmem_max" = 67108864;
        "net.ipv4.tcp_rmem" = "4096 87380 67108864";
        "net.ipv4.tcp_wmem" = "4096 65536 67108864";
        "net.core.somaxconn" = 4096;
        "net.core.netdev_max_backlog" = 8192;
        "net.ipv4.ip_local_port_range" = "1024 65535";
        "net.ipv4.tcp_tw_reuse" = 1;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_fin_timeout" = 15;
        "net.ipv4.tcp_max_syn_backlog" = 8192;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.core.optmem_max" = 2097152;
        "net.ipv4.tcp_max_tw_buckets" = 65536;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };

    };
}
