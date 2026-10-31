{ self, ... }:
{
  flake.nixosModules.hostmetrics =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      shipJournal = config.telemetry.role == "client";
      smartctl = config.services.prometheus.exporters.smartctl;
      stateDirectory = "/var/lib/opentelemetry-collector";
      priorityNames = [
        "emerg"
        "alert"
        "crit"
        "err"
        "warning"
        "notice"
        "info"
        "debug"
      ];
      journaldStatements = [
        ''set(log.attributes["job"], "Systemd")''
        ''set(log.attributes["unit"], log.body["_SYSTEMD_UNIT"]) where log.body["_SYSTEMD_UNIT"] != nil''
        ''set(log.attributes["unit"], "user-session.scope") where IsMatch(log.attributes["unit"], "^session-\\d+\\.scope$")''
        ''set(log.attributes["transport"], log.body["_TRANSPORT"]) where log.body["_TRANSPORT"] != nil''
        ''set(log.attributes["hostname"], log.body["_HOSTNAME"]) where log.body["_HOSTNAME"] != nil''
        ''set(log.attributes["facility"], log.body["SYSLOG_FACILITY"]) where log.body["SYSLOG_FACILITY"] != nil''
      ]
      ++ lib.imap0 (
        num: name:
        ''set(log.attributes["level"], "${name}") where log.body["PRIORITY"] == "${toString num}"''
      ) priorityNames
      ++ [ ''set(log.body, log.body["MESSAGE"]) where log.body["MESSAGE"] != nil'' ];
    in
    {

      # Alloy 1.17.1 has no hostmetrics receiver in its default engine, only
      # under `alloy otel`, which services.alloy can't launch. Recheck for a
      # native otelcol.receiver.hostmetrics and drop otelcol-contrib if it lands.
      services.opentelemetry-collector = {
        enable = true;
        package = pkgs.opentelemetry-collector-contrib;
        settings = {
          extensions = lib.optionalAttrs shipJournal {
            file_storage.directory = stateDirectory;
          };
          receivers = {
            hostmetrics = {
              collection_interval = "60s";
              scrapers = {
                cpu.metrics = {
                  "system.cpu.utilization".enabled = true;
                  "system.cpu.logical.count".enabled = true;
                };
                memory.metrics."system.memory.utilization".enabled = true;
                disk = { };
                filesystem.metrics."system.filesystem.utilization".enabled = true;
                load = { };
                network = { };
                processes = { };
                paging = { };
                process = {
                  mute_process_name_error = true;
                  mute_process_exe_error = true;
                  mute_process_io_error = true;
                  mute_process_user_error = true;
                  metrics = {
                    "process.cpu.time".enabled = false;
                    "process.cpu.utilization".enabled = true;
                    "process.disk.io".enabled = false;
                    "process.memory.virtual".enabled = false;
                    "process.memory.utilization".enabled = true;
                  };
                };
              };
            };
            systemd.collection_interval = "60s";
          }
          // lib.optionalAttrs smartctl.enable {
            # SMART attributes move slowly; a 5m scrape keeps OneUptime's
            # ClickHouse growth down on media's nearly full eMMC.
            prometheus.config.scrape_configs = [
              {
                job_name = "SMART";
                scrape_interval = "300s";
                static_configs = [
                  { targets = [ "127.0.0.1:${toString smartctl.port}" ]; }
                ];
              }
            ];
          }
          // lib.optionalAttrs shipJournal {
            journald = {
              priority = "debug";
              start_at = "end";
              storage = "file_storage";
            };
          };
          processors = {
            resourcedetection = {
              detectors = [
                "system"
                "env"
              ];
              system.hostname_sources = [ "os" ];
            };
            batch = { };
          }
          // lib.optionalAttrs shipJournal {
            transform = {
              error_mode = "ignore";
              log_statements = [
                {
                  context = "log";
                  statements = journaldStatements ++ self.lib.telemetryLogStatements { inherit config; };
                }
              ];
            };
          };
          exporters.otlphttp = {
            endpoint = "${config.telemetry.agent.url}/otlp";
            headers."x-oneuptime-token" = "\${env:ONEUPTIME_INGESTION_TOKEN}";
          };
          service = {
            telemetry.metrics.level = "none";
            extensions = lib.optionals shipJournal [ "file_storage" ];
            pipelines = {
              metrics = {
                receivers = [
                  "hostmetrics"
                  "systemd"
                ]
                ++ lib.optional smartctl.enable "prometheus";
                processors = [
                  "resourcedetection"
                  "batch"
                ];
                exporters = [ "otlphttp" ];
              };
            }
            // lib.optionalAttrs shipJournal {
              logs = {
                receivers = [ "journald" ];
                processors = [
                  "resourcedetection"
                  "transform"
                  "batch"
                ];
                exporters = [ "otlphttp" ];
              };
            };
          };
        };
      };

      systemd.services.opentelemetry-collector = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          EnvironmentFile = config.sops.templates."opentelemetry-collector.env".path;
          AmbientCapabilities = [
            "CAP_DAC_READ_SEARCH"
            "CAP_SYS_PTRACE"
          ];
          CapabilityBoundingSet = [
            "CAP_DAC_READ_SEARCH"
            "CAP_SYS_PTRACE"
          ];
          RestartSec = 30;
        };
      };

    };
}
