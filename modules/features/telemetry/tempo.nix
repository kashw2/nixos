{ self, inputs, ... }:
{
  flake.nixosModules.tempo =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      config = lib.mkIf (config.features.telemetry.role == "host") {

        networking.firewall.allowedTCPPorts = lib.optionals config.services.tempo.enable [
          config.services.tempo.settings.server.http_listen_port
          5317 # OTLP gRPC
          5318 # OTLP HTTP
        ];

        services.tempo = {
          enable = true;
          settings = {
            server.http_listen_port = 3200;
            distributor.receivers.otlp.protocols = {
              grpc.endpoint = "0.0.0.0:5317";
              http.endpoint = "0.0.0.0:5318";
            };
            compactor.compaction.block_retention = "48h";
            storage = {
              trace = {
                backend = "local";
                local.path = "/var/lib/tempo";
                wal.path = "/var/lib/tempo";
              };
            };
            metrics_generator = {
              registry.external_labels = {
                source = "tempo";
              };
              storage.path = "/var/lib/tempo";
            };
            overrides.defaults.metrics_generator.processors = [
              "service_graphs"
              "span_metrics"
            ];
          };
        };

      };
    };
}
