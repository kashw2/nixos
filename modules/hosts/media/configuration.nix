{ self, inputs, ... }:
{
  flake.nixosModules.media =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {

      imports = [
        self.nixosModules.mediaHardwareConfiguration
        self.nixosModules.mediaDiskoConfiguration
        self.nixosModules.serverTemplate
        self.nixosModules.jellyfin
        self.nixosModules.keanu
      ];

      features.telemetry.role = "host";

      networking = {
        hostName = "media";
        defaultGateway = {
          address = "192.168.1.1";
          interface = "enp4s0";
        };
        useNetworkd = true;
        firewall.allowedTCPPorts = [
          80 # Nginx
          8096 # Jellyfin
          config.services.prowlarr.settings.server.port
          config.services.sonarr.settings.server.port
          config.services.radarr.settings.server.port
          config.services.lidarr.settings.server.port
          config.services.bazarr.listenPort
          config.services.flaresolverr.port
          config.services.flood.port
          config.services.deluge.web.port
          config.services.deluge.config.daemon_port
          (lib.toInt config.services.uptime-kuma.settings.PORT)
          5201 # iperf3
        ];
        interfaces = {
          enp4s0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.12";
                prefixLength = 24;
              }
            ];
          };
          enp3s0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.12";
                prefixLength = 24;
              }
            ];
          };
        };
      };

      systemd.network = {
        enable = true;
        networks = {
          "40-enp4s0" = {
            enable = true;
            name = "enp4s0";
            gateway = [ "192.168.1.1" ];
            address = [ "192.168.1.12" ];
            routes = [
              {
                Gateway = "192.168.1.1";
              }
            ];
            matchConfig = {
              Name = "enp4s0";
              Host = "media";
              MACAddress = "e0:51:d8:1c:eb:c8";
            };
            networkConfig = {
              DHCP = "no";
              IPv6PrivacyExtensions = "kernel";
            };
            linkConfig.RequiredForOnline = "routable";
          };
          "40-enp3s0" = {
            enable = true;
            name = "enp3s0";
            gateway = [ "192.168.1.1" ];
            address = [ "192.168.1.12" ];
            routes = [
              {
                Gateway = "192.168.1.1";
              }
            ];
            matchConfig = {
              Name = "enp3s0";
              Host = "media";
              MACAddress = "e0:51:d8:1c:eb:c7";
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

      services = {
        nginx =
          let
            mkVirtualHost = name: port: {
              "${name}" = {
                serverName = "${name}.${config.networking.hostName}.local";
                locations = {
                  "/" = {
                    proxyPass = "http://127.0.0.1:${toString port}/";
                    extraConfig = ''
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto $scheme;
                      proxy_set_header Cookie $http_cookie;
                      proxy_set_header Authorization $http_authorization;
                    '';
                  };
                };
              };
            };
          in
          {
            enable = true;
            statusPage = true;
            virtualHosts =
              mkVirtualHost "jellyfin" 8096
              // mkVirtualHost "alloy" 12345
              // mkVirtualHost "prowlarr" config.services.prowlarr.settings.server.port
              // mkVirtualHost "sonarr" config.services.sonarr.settings.server.port
              // mkVirtualHost "radarr" config.services.radarr.settings.server.port
              // mkVirtualHost "lidarr" config.services.lidarr.settings.server.port
              // mkVirtualHost "bazarr" config.services.bazarr.listenPort
              // mkVirtualHost "flaresolverr" config.services.flaresolverr.port
              // mkVirtualHost "flood" config.services.flood.port
              // mkVirtualHost "deluge" config.services.deluge.web.port
              // mkVirtualHost "mimir" config.services.mimir.configuration.server.http_listen_port
              // mkVirtualHost "grafana" config.services.grafana.settings.server.http_port
              // mkVirtualHost "loki" config.services.loki.configuration.server.http_listen_port
              // mkVirtualHost "tempo" config.services.tempo.settings.server.http_listen_port
              // mkVirtualHost "uptime" config.services.uptime-kuma.settings.PORT;
          };

        prowlarr.enable = true;
        sonarr.enable = true;
        radarr.enable = true;
        lidarr.enable = true;
        bazarr.enable = true;
        flaresolverr.enable = true;
        uptime-kuma.enable = true;

        flood = {
          enable = true;
          host = "0.0.0.0";
          port = 5517;
        };

        deluge = {
          enable = true;
          declarative = true;
          authFile = pkgs.writeText "auth" ''
            localclient:3e44dc790d0bc9f6d76a37af26e7cba72d93cb1d:10
          '';
          dataDir = "/mnt/torrents";
          config = {
            auto_managed = true;
            allow_remote = true;
            daemon_port = 58846;

            # Connection limits (conservative for N150 4-core / 12GB RAM)
            max_connections_global = 1500;
            max_connections_per_second = 200;
            max_connections_per_torrent = 75;
            max_half_open_connections = 100;

            # Active torrents
            max_active_limit = 500;
            max_active_seeding = 500;
            max_active_downloading = 20;

            # Upload slots
            max_upload_slots_global = 500;
            max_upload_slots_per_torrent = 8;

            # Speeds — unlimited for seedbox
            max_upload_speed = -1.0;
            max_download_speed = -1.0;

            # Seeding policy
            share_ratio_limit = 2;
            seed_time_limit = 60;
            seed_time_ratio_limit = 1;
            stop_seed_ratio = config.services.deluge.config.share_ratio_limit;
            remove_seed_at_ratio = true;

            # Cache — 256MB (16384 pieces × 16KB)
            cache_size = 16384;
            cache_expiry = 120;

            # Don't count slow peers against limits
            dont_count_slow_torrents = true;

            # Encryption
            enc_in_policy = 1;
            enc_out_policy = 1;
            enc_level = 1;

            # Disable phone-home
            send_info = false;
            new_release_check = false;
          };
          web.enable = true;
        };

      };

    };
}
