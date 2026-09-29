{ self, inputs, ... }:
{
  flake.nixosModules.telemetry =
    {
      config,
      lib,
      ...
    }:
    {

      imports = [
        self.nixosModules.alloy
        self.nixosModules.snmpd
        self.nixosModules.hostmetrics
        self.nixosModules.oneuptimeInfrastructureAgent
      ];

      options.telemetry.role = lib.mkOption {
        type = lib.types.enum [
          "host"
          "client"
        ];
        default = "client";
        description = "Whether this machine is a telemetry host (runs the Alloy collector) or a client (only exports metrics).";
      };

      config = {
        networking.firewall.allowedTCPPorts =
          [ ]
          ++ lib.optionals (config.services.prometheus.exporters.node.enable) [
            config.services.prometheus.exporters.node.port
          ]
          ++ lib.optionals (config.services.prometheus.exporters.nvidia-gpu.enable) [
            config.services.prometheus.exporters.nvidia-gpu.port
          ];

        services = {
          logrotate =
            let
              mkLogRotateSetting = name: filePath: {
                ${name} = {
                  compress = true;
                  delaycompress = true;
                  files = filePath;
                  frequency = "daily";
                  rotate = 7;
                };
              };
            in
            {
              enable = true;
              checkConfig = true;
              settings =
                mkLogRotateSetting "messages" "/var/log/messages" // mkLogRotateSetting "warn" "/var/log/warn";
            };
          rsyslogd = {
            enable = true;
            extraConfig = ''
              auth,authpriv.*              -/var/log/auth.log
              kern.*                       -/var/log/kernel.log
              cron.*                       -/var/log/cron.log
              user.*                       -/var/log/user.log
            '';
          };
          journald.extraConfig = "MaxRetentionSec=30day";
          prometheus = {
            exporters = {
              node = {
                enable = true;
                enabledCollectors = [ "systemd" ];
                port = 9002;
              };
              postgres = {
                enable = config.services.postgresql.enable;
                runAsLocalSuperUser = true;
                port = 9187;
              };
              nvidia-gpu = {
                enable = builtins.elem "nvidia" config.services.xserver.videoDrivers;
                port = 9835;
              };
            };
          };
        };
      };

    };
}
