{ self, inputs, ... }:
{
  flake.nixosModules.prometheus =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      config = lib.mkIf (config.features.telemetry.role == "host") {

        networking.firewall.allowedTCPPorts = lib.optionals config.services.prometheus.enable [
          config.services.prometheus.port
        ];

        services.prometheus = {
          enable = true;
          port = 9090;
          globalConfig.scrape_interval = "5s";
          extraFlags = [
            "--storage.tsdb.retention.time=365d"
            "--storage.tsdb.retention.size=30GB"
            "--web.enable-remote-write-receiver"
          ];
          scrapeConfigs = [
            {
              job_name = "nixosConfiguration";
              static_configs = [
                {
                  targets = [
                    "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.5:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.6:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.7:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.8:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.9:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.10:${toString config.services.prometheus.exporters.node.port}"
                    "192.168.1.11:${toString config.services.prometheus.exporters.node.port}"
                  ];
                }
              ];
            }
            {
              job_name = "OpenWRT";
              honor_labels = true;
              static_configs = [
                {
                  targets = [ "${config.networking.defaultGateway.address}:9100" ];
                }
              ];
            }
          ];
        };

      };
    };
}
