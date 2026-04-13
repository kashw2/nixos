{ self, inputs, ... }:
{
  flake.nixosModules.mimir =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      config = lib.mkIf (config.features.telemetry.role == "host") {

        networking.firewall.allowedTCPPorts = lib.optionals config.services.mimir.enable [
          config.services.mimir.configuration.server.http_listen_port
          config.services.mimir.configuration.server.grpc_listen_port
        ];

        services.mimir = {
          enable = true;
          configuration = {
            target = "all";
            multitenancy_enabled = false;

            server = {
              http_listen_port = 9009;
              grpc_listen_port = 9097;
            };

            common = {
              storage = {
                backend = "filesystem";
                filesystem = {
                  dir = "/var/lib/mimir/data";
                };
              };
            };

            blocks_storage = {
              backend = "filesystem";
              bucket_store.sync_dir = "/var/lib/mimir/tsdb-sync";
              filesystem.dir = "/var/lib/mimir/blocks";
              tsdb = {
                dir = "/var/lib/mimir/tsdb";
                retention_period = "8760h";
              };
            };

            compactor = {
              data_dir = "/var/lib/mimir/compactor";
              sharding_ring.kvstore.store = "memberlist";
            };

            distributor.ring = {
              instance_addr = "127.0.0.1";
              kvstore.store = "memberlist";
            };

            ingester.ring = {
              instance_addr = "127.0.0.1";
              kvstore.store = "memberlist";
              replication_factor = 1;
            };

            store_gateway.sharding_ring = {
              replication_factor = 1;
              kvstore.store = "memberlist";
            };

            ruler_storage = {
              backend = "filesystem";
              filesystem.dir = "/var/lib/mimir/rules";
            };

            limits = {
              compactor_blocks_retention_period = "8760h";
            };
          };
        };

      };
    };
}
