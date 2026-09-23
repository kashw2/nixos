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
                  `set(resource.attributes["service.name"], attributes["job"]) where resource.attributes["service.name"] == nil and attributes["job"] != nil`,
                  `set(resource.attributes["host.name"], attributes["hostname"]) where resource.attributes["host.name"] == nil and attributes["hostname"] != nil`,
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
            ${lib.optionalString config.security.auditd.enable ''
              loki.source.file "audit_log" {
                targets = [
                  {
                  "__path__" = "/var/log/audit/audit.log",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Auditd",
                  "labels" = {},
                  },
                ]
                forward_to = [
                  otelcol.receiver.loki.default.receiver,
                ]
              }
            ''}
            ${lib.optionalString config.services.rsyslogd.enable ''
              loki.source.file "syslog_log" {
                targets = [
                  {
                  "__path__" = "/var/log/warn",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Syslog",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/messages",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Syslog",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/mail",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Syslog",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/dhcpd",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Syslog",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/auth.log",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Authentication",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/kernel.log",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Kernel",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/cron.log",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Cron",
                  "labels" = {},
                  },
                  {
                  "__path__" = "/var/log/user.log",
                  "hostname" = "${config.networking.hostName}",
                  "job" = "Auditd",
                  "labels" = {},
                  },
                ]
                forward_to = [
                  otelcol.receiver.loki.default.receiver,
                ]
              }
            ''}
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
