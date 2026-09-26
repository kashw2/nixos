{ self, ... }:
{
  flake.nixosModules.oneuptimeApp =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.oneuptime;
    in
    {

      config = lib.mkIf cfg.enable {

        oneuptime.settings = lib.mapAttrs (_: lib.mkDefault) {
          HOST = cfg.host;
          HTTP_PROTOCOL = cfg.httpProtocol;
          PORT = toString cfg.port;
          APP_PORT = toString cfg.port;
          STATUS_PAGE_CNAME_RECORD = cfg.host;
          DASHBOARD_CNAME_RECORD = cfg.host;
          DATABASE_PORT = toString config.services.postgresql.settings.port;
          CLICKHOUSE_HOST = config.services.clickhouse.serverConfig.listen_host;
          CLICKHOUSE_PORT = toString config.services.clickhouse.serverConfig.http_port;
          REDIS_HOST = config.services.redis.servers.oneuptime.bind;
          REDIS_PORT = toString config.services.redis.servers.oneuptime.port;
          NODE_ENV = "production";
          LOG_LEVEL = "ERROR";
          TRUSTED_PROXY_HOPS = "1";
          BILLING_ENABLED = "false";
          IS_ENTERPRISE_EDITION = "false";
          DISABLE_TELEMETRY = "true";
          DISABLE_UPDATE_CHECK = "true";
          GOOGLE_TAG_MANAGER_ENABLED = "false";
          CAPTCHA_ENABLED = "false";
          WORKER_CONCURRENCY = "100";
          TELEMETRY_CONCURRENCY = "100";
          MQTT_INGEST_ENABLED = "false";
          ALLOW_PRIVATE_NETWORK_WEBHOOKS = "true";
          PROBE_ALLOW_PRIVATE_NETWORK_MONITORS = "true";
        };

        systemd.services.oneuptime-migrate = {
          description = "OneUptime database migrations";
          after = [
            "postgresql.service"
            "clickhouse.service"
            "redis-oneuptime.service"
          ];
          requires = [
            "postgresql.service"
            "clickhouse.service"
            "redis-oneuptime.service"
          ];
          before = [ "oneuptime-app.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = cfg.settings;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "oneuptime";
            Group = "oneuptime";
            StateDirectory = "oneuptime";
            EnvironmentFile = config.sops.templates."oneuptime.env".path;
            ExecStart =
              lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.oneuptime-app
                "oneuptime-app-migrate";
            TimeoutStartSec = "10min";
            Restart = "on-failure";
            RestartSec = 30;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };

        systemd.services.oneuptime-app = {
          description = "OneUptime";
          after = [
            "oneuptime-migrate.service"
            "postgresql.service"
            "clickhouse.service"
            "redis-oneuptime.service"
          ];
          requires = [ "oneuptime-migrate.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = cfg.settings;
          serviceConfig = {
            User = "oneuptime";
            Group = "oneuptime";
            StateDirectory = "oneuptime";
            EnvironmentFile = config.sops.templates."oneuptime.env".path;
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.oneuptime-app;
            Restart = "always";
            RestartSec = 10;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };

      };
    };
}
