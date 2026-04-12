{ self, inputs, ... }:
{
  flake.nixosModules.loki =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      config = lib.mkIf (config.features.telemetry.role == "host") {

        networking.firewall.allowedTCPPorts = [
          config.services.loki.configuration.server.http_listen_port
          config.services.loki.configuration.server.grpc_listen_port
        ];

        services.loki = {
          enable = true;
          configuration = {
            auth_enabled = false;
            server = {
              http_listen_port = 3100;
              grpc_listen_port = 9096;
              grpc_server_max_concurrent_streams = 1000;
            };
            common = {
              instance_addr = "127.0.0.1";
              path_prefix = "/tmp/loki";
              storage = {
                filesystem = {
                  chunks_directory = "/tmp/loki/chunks";
                  rules_directory = "/tmp/loki/rules";
                };
              };
              replication_factor = 1;
              ring = {
                kvstore = {
                  store = "inmemory";
                };
              };
            };
            query_range = {
              results_cache = {
                cache = {
                  embedded_cache = {
                    enabled = true;
                    max_size_mb = 100;
                  };
                };
              };
            };
            limits_config = {
              metric_aggregation_enabled = true;
            };
            schema_config = {
              configs = [
                {
                  from = "2020-10-24";
                  store = "tsdb";
                  object_store = "filesystem";
                  schema = "v13";
                  index = {
                    prefix = "index_";
                    period = "24h";
                  };
                }
              ];
            };
            pattern_ingester = {
              enabled = true;
              metric_aggregation = {
                loki_address = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
              };
            };
            frontend = {
              encoding = "protobuf";
            };
          };
        };

      };
    };
}
