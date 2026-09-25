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

      telemetry.role = "host";

      oneuptime = {
        enable = true;
        runner.enable = true;

        settings = {
          PROVISION_SSL = "false";
          DATABASE_HOST = "127.0.0.1";
          DATABASE_NAME = "oneuptime";
          DATABASE_USERNAME = "oneuptime";
          DATABASE_SSL_REJECT_UNAUTHORIZED = "false";
          CLICKHOUSE_USER = "default";
          CLICKHOUSE_DATABASE = "oneuptime";
          REDIS_USERNAME = "default";
          REDIS_DB = "0";
        };

        probe.settings = {
          PROBE_ID = "e1a57509-9539-4e1e-ad60-f1378ae1a105";
          PROBE_NAME = "Probe-1";
          PROBE_DESCRIPTION = "Private probe to monitor oneuptime resources";
        };

        runner.settings.ONEUPTIME_RUNNER_ID = "3ac93117-92ed-4874-a9bb-0b4c6b594b2d";
      };

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
          ++ lib.optionals config.services.postgresql.enable [ "/var/lib/postgresql" ]
          ++ lib.optionals config.services.clickhouse.enable [ "/var/lib/clickhouse" ]
          ++ lib.optionals config.oneuptime.enable [
            "/var/lib/redis-oneuptime"
            "/var/lib/oneuptime"
          ]
          ++ lib.optionals config.oneuptime.probe.enable [ "/var/lib/oneuptime-probe" ]
          ++ lib.optionals config.oneuptime.runner.enable [ "/var/lib/oneuptime-runner" ];
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
        firewall.allowedUDPPorts = [ config.services.rtorrent.port ];
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
            domains = [ "~local" ];
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
                    proxyWebsockets = true;
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
            mkOneUptimeRewrite = pattern: {
              proxyPass = "http://127.0.0.1:${toString config.oneuptime.port}";
              proxyWebsockets = true;
              extraConfig = ''
                rewrite ${pattern} break;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Cookie $http_cookie;
                proxy_set_header Authorization $http_authorization;
              '';
            };
          in
          {
            enable = true;
            statusPage = true;
            virtualHosts =
              mkVirtualHost "jellyfin" 8096
              // mkVirtualHost "alloy" 12345
              // lib.recursiveUpdate (mkVirtualHost "oneuptime" config.oneuptime.port) {
                oneuptime.locations = {
                  "/identity" = mkOneUptimeRewrite "^/identity(.*)$ /api/identity$1";
                  "/notification" = mkOneUptimeRewrite "^/notification(.*)$ /api/notification$1";
                  "/file" = mkOneUptimeRewrite "^/file(.*)$ /api/file$1";
                  "/workers" = mkOneUptimeRewrite "^/workers(.*)$ /api/workers$1";
                  "/heartbeat" = mkOneUptimeRewrite "^/heartbeat(.*)$ /incoming-request$1";
                  "/l/" = mkOneUptimeRewrite "^/l/(.*)$ /api/short-link/redirect-to-shortlink/$1";
                  "/status-page-api/" = mkOneUptimeRewrite "^/status-page-api/(.*)$ /api/status-page/$1";
                  "/status-page-identity-api/" =
                    mkOneUptimeRewrite "^/status-page-identity-api/(.*)$ /api/identity/status-page/$1";
                  "/status-page-sso-api/" =
                    mkOneUptimeRewrite "^/status-page-sso-api/(.*)$ /api/identity/status-page-sso/$1";
                  "/status-page-oidc-api/" =
                    mkOneUptimeRewrite "^/status-page-oidc-api/(.*)$ /api/identity/status-page-oidc/$1";
                  "/public-dashboard-api/" = mkOneUptimeRewrite "^/public-dashboard-api/(.*)$ /api/dashboard/$1";
                };
              }
              // mkVirtualHost "prowlarr" config.services.prowlarr.settings.server.port
              // mkVirtualHost "sonarr" config.services.sonarr.settings.server.port
              // mkVirtualHost "radarr" config.services.radarr.settings.server.port
              // mkVirtualHost "bazarr" config.services.bazarr.listenPort
              // mkVirtualHost "flaresolverr" config.services.flaresolverr.port
              // mkVirtualHost "flood" config.services.flood.port
              // {
                "rtorrent-rpc" = {
                  listen = [
                    {
                      addr = "127.0.0.1";
                      port = 8000;
                    }
                  ];
                  locations."/RPC2".extraConfig = ''
                    scgi_param CONTENT_LENGTH $content_length;
                    scgi_param SCGI 1;
                    scgi_param SCRIPT_NAME /RPC2;
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

            # DHT bootstrap nodes — routing table starts empty and never seeds otherwise
            dht.add_node = "router.bittorrent.com:6881"
            dht.add_node = "dht.transmissionbt.com:6881"
            dht.add_node = "router.utorrent.com:6881"

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
          '';
        };

        postgresql = lib.mkIf config.oneuptime.enable {
          enable = true;
          authentication = "host oneuptime oneuptime 127.0.0.1/32 trust";
          ensureDatabases = [ config.oneuptime.settings.DATABASE_NAME ];
          ensureUsers = [
            {
              name = config.oneuptime.settings.DATABASE_USERNAME;
              ensureDBOwnership = true;
            }
          ];
        };

        redis.servers.oneuptime = lib.mkIf config.oneuptime.enable {
          enable = true;
          bind = "127.0.0.1";
          port = 6379;
          save = [ ];
          appendOnly = false;
        };

        clickhouse = lib.mkIf config.oneuptime.enable {
          enable = true;
          serverConfig = {
            listen_host = "127.0.0.1";
            http_port = 8123;
            tcp_port = 9000;
            max_server_memory_usage_to_ram_ratio = 0.5;
            prometheus = {
              endpoint = "/metrics";
              port = 9363;
              metrics = true;
              events = true;
              asynchronous_metrics = true;
              errors = true;
            };
            keeper_server = {
              tcp_port = 9181;
              server_id = 1;
              log_storage_path = "/var/lib/clickhouse/coordination/log";
              snapshot_storage_path = "/var/lib/clickhouse/coordination/snapshots";
              coordination_settings = {
                operation_timeout_ms = 10000;
                session_timeout_ms = 30000;
                raft_logs_level = "warning";
              };
              raft_configuration.server = {
                id = 1;
                hostname = "127.0.0.1";
                port = 9234;
              };
            };
            zookeeper.node = {
              host = "127.0.0.1";
              port = 9181;
            };
            macros = {
              shard = "01";
              replica = "replica-1";
              cluster = "oneuptime";
            };
            remote_servers.oneuptime.shard = {
              internal_replication = true;
              replica = {
                host = "127.0.0.1";
                port = 9000;
              };
            };
          };
          extraUsersConfig = ''
            <clickhouse>
              <users>
                <default>
                  <password remove="1"/>
                  <no_password/>
                  <networks>
                    <ip>127.0.0.1</ip>
                  </networks>
                  <access_management>1</access_management>
                </default>
              </users>
            </clickhouse>
          '';
          extraServerConfig = ''
            <clickhouse>
                <query_log>
                    <database>system</database>
                    <table>query_log</table>
                    <partition_by>toYYYYMM(event_date)</partition_by>
                    <ttl>event_time + INTERVAL 6 HOUR DELETE</ttl>
                    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
                </query_log>
                <trace_log>
                    <database>system</database>
                    <table>trace_log</table>
                    <partition_by>toYYYYMM(event_date)</partition_by>
                    <ttl>event_time + INTERVAL 6 HOUR DELETE</ttl>
                    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
                </trace_log>
                <text_log>
                    <database>system</database>
                    <table>text_log</table>
                    <partition_by>toYYYYMM(event_date)</partition_by>
                    <ttl>event_time + INTERVAL 6 HOUR DELETE</ttl>
                    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
                </text_log>
                <part_log>
                    <database>system</database>
                    <table>part_log</table>
                    <partition_by>toYYYYMM(event_date)</partition_by>
                    <ttl>event_time + INTERVAL 6 HOUR DELETE</ttl>
                    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
                </part_log>
                <metric_log>
                    <database>system</database>
                    <table>metric_log</table>
                    <partition_by>toYYYYMM(event_date)</partition_by>
                    <ttl>event_time + INTERVAL 6 HOUR DELETE</ttl>
                    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
                </metric_log>
                <asynchronous_metric_log>
                    <database>system</database>
                    <table>asynchronous_metric_log</table>
                    <partition_by>toYYYYMM(event_date)</partition_by>
                    <ttl>event_time + INTERVAL 6 HOUR DELETE</ttl>
                    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
                </asynchronous_metric_log>
                <processors_profile_log remove="1" />
            </clickhouse>
          '';
        };

      };

      systemd.tmpfiles.rules = [
        "d /mnt/torrents 2775 rtorrent rtorrent -"
        "d /mnt/torrents/Downloads 2775 rtorrent rtorrent -"
      ];

      systemd.services.postgresql.postStart = lib.mkIf config.oneuptime.enable (
        lib.mkAfter "psql -tAc 'GRANT pg_monitor TO \"${config.oneuptime.settings.DATABASE_USERNAME}\"'\n"
      );

      systemd.services.rtorrent.serviceConfig.LimitNOFILE = 32768;

      systemd.services.flood.serviceConfig.SupplementaryGroups = [ "rtorrent" ];

    };
}
