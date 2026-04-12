{ self, inputs, ... }:
{
  flake.nixosModules.grafana =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      config = lib.mkIf (config.features.telemetry.role == "host") {

        networking.firewall.allowedTCPPorts = lib.optionals config.services.grafana.enable [
          config.services.grafana.settings.server.http_port
        ];

        environment = {
          etc = {
            "grafana/dashboards/node-exporter-full.json".source = ./node-exporter-full.json;
          };
        };

        services.grafana = {
          enable = true;
          settings = {
            server = {
              http_addr = "127.0.0.1";
              http_port = 3000;
            };
            limits_config = {
              volume_enabled = true;
            };
            security.secret_key = "5c2fd69cb13a873406a2dc5fbdaca973352fe08f8fa4f5e70a8c873fb08ed1e5";
          };
          provision = {
            enable = true;
            datasources = {
              settings = {
                datasources = [
                  {
                    name = "Prometheus";
                    type = "prometheus";
                    url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                    editable = false;
                  }
                  {
                    name = "Loki";
                    type = "loki";
                    url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                    editable = true;
                  }
                  {
                    name = "Tempo";
                    type = "tempo";
                    url = "http://127.0.0.1:${toString config.services.tempo.settings.server.http_listen_port}";
                    editable = true;
                  }
                ];
                deleteDatasources = [
                  {
                    name = "Prometheus";
                    orgId = 1;
                  }
                  {
                    name = "Tempo";
                    orgId = 1;
                  }
                  {
                    name = "Loki";
                    orgId = 1;
                  }
                ];
              };
            };
            dashboards.settings.providers = [
              {
                name = "Dashboards";
                options.path = "/etc/grafana/dashboards";
              }
            ];
          };
        };

      };
    };
}
