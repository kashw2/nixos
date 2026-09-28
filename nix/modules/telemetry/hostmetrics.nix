{ ... }:
{
  flake.nixosModules.hostmetrics =
    {
      config,
      pkgs,
      ...
    }:
    {

      # Alloy 1.17.1 has no hostmetrics receiver in its default engine, only
      # under `alloy otel`, which services.alloy can't launch. Recheck for a
      # native otelcol.receiver.hostmetrics and drop otelcol-contrib if it lands.
      services.opentelemetry-collector = {
        enable = true;
        package = pkgs.opentelemetry-collector-contrib;
        settings = {
          receivers.hostmetrics = {
            collection_interval = "30s";
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
                  "process.cpu.utilization".enabled = true;
                  "process.memory.utilization".enabled = true;
                };
              };
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
          };
          exporters.otlphttp = {
            endpoint = "${config.telemetry.agent.url}/otlp";
            headers."x-oneuptime-token" = "\${env:ONEUPTIME_INGESTION_TOKEN}";
          };
          service = {
            telemetry.metrics.level = "none";
            pipelines.metrics = {
              receivers = [ "hostmetrics" ];
              processors = [
                "resourcedetection"
                "batch"
              ];
              exporters = [ "otlphttp" ];
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
