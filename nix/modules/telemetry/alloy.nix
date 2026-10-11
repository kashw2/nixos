{ self, ... }:
{
  flake.nixosModules.alloy =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      scrapeAddresses = {
        openwrt = config.networking.defaultGateway.address;
      };
      scrapeTargets = lib.concatMapStringsSep "\n            " (
        addr: ''{"__address__" = "${addr}:${toString config.services.prometheus.exporters.node.port}"},''
      ) (lib.attrValues scrapeAddresses);
      metricGroups = {
        "alloy" = "Alloy";
        "prometheus.scrape.openwrt" = "OpenWrt";
        "prometheus.scrape.clickhouse" = "ClickHouse";
        "prometheus.scrape.postgres" = "PostgreSQL";
      };
      metricStatements = lib.concatStringsSep "\n      " (
        lib.mapAttrsToList (
          from: to:
          "`set(attributes[\"service.name\"], \"${to}\") where attributes[\"service.name\"] == \"${from}\"`,"
        ) metricGroups
        ++ lib.mapAttrsToList (
          name: addr:
          "`set(attributes[\"host.name\"], \"${name}\") where attributes[\"server.address\"] == \"${addr}\"`,"
        ) scrapeAddresses
      );
      logStatements = lib.concatMapStringsSep "\n                  " (statement: "`${statement}`,") (
        self.lib.telemetryLogStatements { inherit config; }
      );
    in
    {

      services.alloy = {
        enable = config.telemetry.role == "host";
        configPath = pkgs.writeText "config.alloy" (
          ''
            logging {
              level = "warn"
              format = "json"
            }
            livedebugging {
              enabled = true
            }
          ''
          + ''
            otelcol.receiver.otlp "default" {
              grpc {
                endpoint = "127.0.0.1:4317"
              }
              http {
                endpoint = "127.0.0.1:4318"
              }
              output {
                metrics = [otelcol.processor.batch.batch.input]
                logs    = [otelcol.processor.batch.batch.input]
                traces  = [otelcol.processor.batch.batch.input]
              }
            }
            otelcol.processor.batch "batch" {
              output {
                metrics = [otelcol.processor.resourcedetection.host.input]
                logs    = [otelcol.processor.resourcedetection.host.input]
                traces  = [otelcol.processor.resourcedetection.host.input]
              }
            }
            otelcol.processor.resourcedetection "host" {
              detectors = ["system"]
              system {
                hostname_sources = ["os"]
              }
              output {
                metrics = [otelcol.processor.transform.entities.input]
                logs    = [otelcol.processor.transform.entities.input]
                traces  = [otelcol.processor.transform.entities.input]
              }
            }
            otelcol.processor.transform "entities" {
              error_mode = "ignore"
              log_statements {
                context = "log"
                statements = [
                  ${logStatements}
                ]
              }
              metric_statements {
                context = "resource"
                statements = [
                  ${metricStatements}
                ]
              }
              output {
                metrics = [otelcol.exporter.otlphttp.oneuptime.input]
                logs    = [otelcol.exporter.otlphttp.oneuptime.input]
                traces  = [otelcol.exporter.otlphttp.oneuptime.input]
              }
            }
            local.file "oneuptime_token" {
              filename  = "/run/credentials/alloy.service/oneuptime-token"
              is_secret = true
            }
            otelcol.auth.headers "oneuptime" {
              header {
                key   = "x-oneuptime-token"
                value = local.file.oneuptime_token.content
              }
            }
            otelcol.exporter.otlphttp "oneuptime" {
              client {
                endpoint = "${config.telemetry.agent.url}/otlp"
                auth     = otelcol.auth.headers.oneuptime.handler
              }
            }
            otelcol.receiver.loki "default" {
              output {
                logs = [otelcol.processor.batch.batch.input]
              }
            }
          ''
          + ''
            otelcol.receiver.prometheus "default" {
              output {
                metrics = [otelcol.processor.batch.batch.input]
              }
            }
            prometheus.scrape "alloy" {
              targets = [{
                job         = "alloy",
                __address__ = "127.0.0.1:12345",
              }]
              forward_to = [
                otelcol.receiver.prometheus.default.receiver,
              ]
            }
            prometheus.scrape "postgres" {
              scrape_interval = "60s"
              scrape_timeout  = "10s"
              targets = [
                {"__address__" = "127.0.0.1:9187"},
              ]
              forward_to = [
                otelcol.receiver.prometheus.default.receiver,
              ]
            }
            prometheus.scrape "clickhouse" {
              scrape_interval = "60s"
              scrape_timeout  = "10s"
              targets = [
                {"__address__" = "127.0.0.1:9363"},
              ]
              forward_to = [
                otelcol.receiver.prometheus.default.receiver,
              ]
            }
            prometheus.scrape "openwrt" {
              scrape_interval = "60s"
              scrape_timeout  = "10s"
              targets = [
                ${scrapeTargets}
              ]
              forward_to = [
                otelcol.receiver.prometheus.default.receiver,
              ]
            }
          ''
          + ''
             ${lib.optionalString config.services.nginx.enable ''
               loki.source.file "nginx_log" {
                 targets = [
                   {
                     "__path__" = "/var/log/nginx/access.log",
                     "hostname" = "${config.networking.hostName}",
                     "job" = "Nginx",
                     "labels" = {},
                   },
                   {
                     "__path__" = "/var/log/nginx/error.log",
                     "hostname" = "${config.networking.hostName}",
                     "job" = "Nginx",
                     "labels" = {},
                   },
                 ]
                 tail_from_end = true
                 forward_to = [
                   otelcol.receiver.loki.default.receiver,
                 ]
               }
             ''}
            loki.relabel "journal" {
              forward_to = []
              rule {
                source_labels = ["__journal__transport"]
                target_label  = "transport"
              }
              rule {
                source_labels = ["__journal__systemd_unit"]
                target_label  = "unit"
              }
              rule {
                source_labels = ["unit"]
                regex         = "session-\\d+\\.scope"
                target_label  = "unit"
                replacement   = "user-session.scope"
              }
              rule {
                source_labels = ["__journal_priority_keyword"]
                target_label  = "level"
              }
              rule {
                source_labels = ["__journal_syslog_facility"]
                target_label  = "facility"
              }
            }
            loki.source.journal "journal" {
              forward_to    = [otelcol.receiver.loki.default.receiver]
              relabel_rules = loki.relabel.journal.rules
              labels = {
                hostname = "${config.networking.hostName}",
                job      = "Systemd",
              }
            }
          ''
        );
        extraFlags = [
          "--server.http.listen-addr=127.0.0.1:12345"
        ];
      };

      systemd.services.alloy = lib.mkIf config.services.alloy.enable {
        serviceConfig = {
          LoadCredential = [
            "oneuptime-token:${config.sops.secrets."oneuptime/ingestion_token".path}"
          ];
          SupplementaryGroups = lib.optionals config.services.nginx.enable [
            config.services.nginx.group
          ];
        };
      };
    };
}
