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
        self.nixosModules.impermanence
        self.nixosModules.serverTemplate
        self.nixosModules.jellyfin
        self.nixosModules.keanu
      ];

      features.telemetry.role = "host";

      # `/mnt/torrents` is owned `rtorrent:rtorrent`; group members can read the
      # tree. Jellyfin and the *arr stack join the `rtorrent` group (the shared
      # media group) so they can read/write downloads and import targets.
      users.users = {
        jellyfin.extraGroups = [ "rtorrent" ];
        sonarr.extraGroups = [ "rtorrent" ];
        radarr.extraGroups = [ "rtorrent" ];
        bazarr.extraGroups = [ "rtorrent" ];
        nginx.extraGroups = [ "rtorrent" ];
      };

      impermanence = {
        enable = true;
        rootDevice = "/dev/disk/by-partlabel/disk-main-root";
        rootDeviceUnit = "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device";
      };

      # persistence. For services that set `DynamicUser = true` in their
      # systemd unit, the real state lives at `/var/lib/private/<name>` —
      # persisting there avoids fighting the symlink systemd creates at
      # `/var/lib/<name>`. rTorrent is intentionally omitted: its `dataDir`
      # is set to `/mnt/torrents/.rtorrent`, which lives on a separate
      # (non-impermanent) disk.
      environment.persistence = lib.mkIf config.impermanence.enable {
        "/persist".directories =
          lib.optionals config.services.jellyfin.enable [ "/var/lib/jellyfin" ]
          ++ lib.optionals config.services.prowlarr.enable [ "/var/lib/private/prowlarr" ]
          ++ lib.optionals config.services.sonarr.enable [ "/var/lib/sonarr" ]
          ++ lib.optionals config.services.radarr.enable [ "/var/lib/radarr" ]
          ++ lib.optionals config.services.bazarr.enable [ "/var/lib/bazarr" ]
          ++ lib.optionals config.services.flood.enable [ "/var/lib/private/flood" ]
          ++ lib.optionals config.services.grafana.enable [ "/var/lib/grafana" ]
          ++ lib.optionals config.services.loki.enable [ "/var/lib/loki" ]
          ++ lib.optionals config.services.mimir.enable [ "/var/lib/private/mimir" ]
          ++ lib.optionals config.services.tempo.enable [ "/var/lib/private/tempo" ];
      };

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
          config.services.bazarr.listenPort
          config.services.flaresolverr.port
          config.services.flood.port
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
                address = "192.168.1.13";
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

      services = {
        nginx =
          let
            mkVirtualHost = name: port: {
              "${name}" = {
                serverName = "${name}.${config.networking.hostName}.local";
                serverAliases = [ "${name}.${config.networking.hostName}.tailscale" ];
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
              // mkVirtualHost "bazarr" config.services.bazarr.listenPort
              // mkVirtualHost "flaresolverr" config.services.flaresolverr.port
              // mkVirtualHost "flood" config.services.flood.port
              // mkVirtualHost "mimir" config.services.mimir.configuration.server.http_listen_port
              // mkVirtualHost "grafana" config.services.grafana.settings.server.http_port
              // mkVirtualHost "loki" config.services.loki.configuration.server.http_listen_port
              // mkVirtualHost "tempo" config.services.tempo.settings.server.http_listen_port
              // {
                "rtorrent-rpc" = {
                  listen = [
                    {
                      addr = "127.0.0.1";
                      port = 8000;
                    }
                  ];
                  locations."/RPC2".extraConfig = ''
                    include ${config.services.nginx.package}/conf/scgi_params;
                    scgi_param SCRIPT_NAME /RPC2;
                    scgi_param CONTENT_LENGTH $content_length;
                    scgi_pass unix:/run/rtorrent/rpc.sock;
                  '';
                };
              };
          };

        prowlarr.enable = true;
        sonarr.enable = true;
        radarr.enable = true;
        bazarr.enable = true;
        flaresolverr.enable = true;

        flood = {
          enable = true;
          host = "0.0.0.0";
          port = 5517;
        };

        rtorrent = {
          enable = true;
          dataDir = "/mnt/torrents/.rtorrent";
          downloadDir = "/mnt/torrents/Downloads";
          port = 50000;
          openFirewall = true;
          configText = lib.mkAfter ''
            # Public-tracker swarm participation
            dht.mode.set = auto
            protocol.pex.set = yes
            trackers.use_udp.set = yes
            protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

            # Unlimited rates (seedbox)
            throttle.global_up.max_rate.set_kb = 0
            throttle.global_down.max_rate.set_kb = 0

            # Scale for ~825 torrents on the N150
            throttle.max_uploads.global.set = 1000
            throttle.max_uploads.set = 8
            throttle.min_peers.normal.set = 1
            throttle.max_peers.normal.set = 100
            throttle.min_peers.seed.set = -1
            throttle.max_peers.seed.set = 100
            trackers.numwant.set = 100
            pieces.memory.max.set = 2000M
            network.max_open_sockets.set = 8000
            network.http.max_open.set = 128
          '';
        };

      };

      systemd.tmpfiles.rules = [
        "d /mnt/torrents 2775 rtorrent rtorrent -"
        "d /mnt/torrents/Downloads 2775 rtorrent rtorrent -"
      ];

      systemd.services.rtorrent.serviceConfig.LimitNOFILE = 32768;

    };
}
