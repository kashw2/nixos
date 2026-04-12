{ ... }:
{
  flake.nixosModules.alloy =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      networking.firewall.allowedTCPPorts =
        [ ]
        ++ lib.optionals config.services.alloy.enable [
          12345
        ];

      services.alloy = {
        enable = config.features.telemetry.role == "host";
        configPath = pkgs.writeText "config.alloy" (
          ''
            logging {
              level = "warn"
            }
            livedebugging {
              enabled = true
            }
          ''
          + lib.optionalString config.services.tempo.enable ''
            otelcol.receiver.otlp "default" {
              grpc {
                endpoint = "127.0.0.1:4317"
              }
              http {
                endpoint = "127.0.0.1:4318"
              }
              output {
                ${lib.optionalString config.services.prometheus.enable ''
                  metrics = [otelcol.processor.batch.batch.input]
                ''}
                ${lib.optionalString config.services.loki.enable ''
                  logs = [otelcol.processor.batch.batch.input]
                ''}
                traces = [otelcol.processor.batch.batch.input]
              }
            }
            otelcol.processor.batch "batch" {
              output {
                ${lib.optionalString config.services.prometheus.enable ''
                  metrics = [
                    otelcol.exporter.prometheus.default.input,
                  ]
                ''}
                ${lib.optionalString config.services.loki.enable ''
                  logs = [
                    otelcol.exporter.loki.default.input,
                  ]
                ''}
                traces = [
                  otelcol.exporter.otlphttp.tempo.input,
                ]
              }
            }
            otelcol.exporter.otlphttp "tempo" {
              client {
                endpoint = "http://192.168.1.7:5318"
              }
            }
            ${lib.optionalString config.services.prometheus.enable ''
              otelcol.exporter.prometheus "default" {
                forward_to = [prometheus.remote_write.writer.receiver]
              }
            ''}
            ${lib.optionalString config.services.loki.enable ''
              otelcol.exporter.loki "default" {
                forward_to = [loki.write.writer.receiver]
              }
            ''}
          ''
          + lib.optionalString config.services.prometheus.exporters.node.enable ''
            prometheus.scrape "default" {
              targets = array.concat(
                [{
                  job         = "alloy",
                  __address__ = "127.0.0.1:12345",
                }],
              )
              forward_to = [
                  prometheus.remote_write.writer.receiver,
              ]
            }
            prometheus.remote_write "writer" {
              endpoint {
                url = "http://192.168.1.7:${toString config.services.prometheus.port}/api/v1/write"
              }
            }
          ''
          + lib.optionalString config.services.loki.enable ''
            loki.write "writer" {
              endpoint {
                url = "http://192.168.1.7:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"
              }
            }
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
                   loki.write.writer.receiver,
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
                  loki.write.writer.receiver,
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
                  loki.write.writer.receiver,
                ]
              }
            ''}
          ''
        );
        extraFlags = [
          "--server.http.listen-addr=127.0.0.1:12345"
        ];
      };
    };
}
