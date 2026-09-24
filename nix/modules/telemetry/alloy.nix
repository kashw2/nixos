{ ... }:
{
  flake.nixosModules.alloy =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # LAN address per host under nix/hosts/. Keep in sync when adding hosts.
      hostAddresses = {
        home = "192.168.1.5";
        laptop = "192.168.1.6";
        homelab = "192.168.1.7";
        thinkpad = "192.168.1.9";
        media = "192.168.1.12";
      };
      scrapeTargets = lib.concatMapStringsSep "\n            " (
        addr: ''{"__address__" = "${addr}:${toString config.services.prometheus.exporters.node.port}"},''
      ) (lib.attrValues hostAddresses);
    in
    {

      services.alloy = {
        enable = config.telemetry.role == "host";
        configPath = pkgs.writeText "config.alloy" (
          ''
            logging {
              level = "warn"
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
                  `set(resource.attributes["service.name"], "Auditd") where attributes["transport"] == "audit"`,
                  `set(resource.attributes["service.name"], attributes["unit"]) where resource.attributes["service.name"] == nil and attributes["unit"] != nil`,
                  `set(resource.attributes["service.name"], attributes["job"]) where resource.attributes["service.name"] == nil and attributes["job"] != nil`,
                  `set(resource.attributes["host.name"], attributes["hostname"]) where resource.attributes["host.name"] == nil and attributes["hostname"] != nil`,
                  `set(severity_text, attributes["level"]) where attributes["level"] != nil`,
                  `set(severity_number, SEVERITY_NUMBER_FATAL) where attributes["level"] == "emerg" or attributes["level"] == "alert" or attributes["level"] == "crit"`,
                  `set(severity_number, SEVERITY_NUMBER_ERROR) where attributes["level"] == "error" or attributes["level"] == "err"`,
                  `set(severity_number, SEVERITY_NUMBER_WARN) where attributes["level"] == "warning" or attributes["level"] == "warn"`,
                  `set(severity_number, SEVERITY_NUMBER_INFO) where attributes["level"] == "notice" or attributes["level"] == "info"`,
                  `set(severity_number, SEVERITY_NUMBER_DEBUG) where attributes["level"] == "debug"`,
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
            prometheus.scrape "nixosConfiguration" {
              scrape_interval = "5s"
              scrape_timeout  = "5s"
              targets = [
                ${scrapeTargets}
              ]
              forward_to = [
                otelcol.receiver.prometheus.default.receiver,
              ]
            }
            prometheus.scrape "openwrt" {
              scrape_interval = "5s"
              scrape_timeout  = "5s"
              honor_labels = true
              targets = [
                {"__address__" = "${config.networking.defaultGateway.address}:9100"},
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
        serviceConfig.LoadCredential = [
          "oneuptime-token:${config.sops.secrets."oneuptime/ingestion_token".path}"
        ];
      };
    };
}
