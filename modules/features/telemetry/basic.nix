{ self, inputs, ... }:
{
  flake.nixosModules.basicTelemetry =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      networking.firewall.allowedTCPPorts =
        [ ]
        ++ lib.optionals (config.services.prometheus.exporters.node.enable) [
          config.services.prometheus.exporters.node.port
        ]
        ++ lib.optionals (config.services.prometheus.exporters.nvidia-gpu.enable) [
          config.services.prometheus.exporters.nvidia-gpu.port
        ];

      services = {
        rsyslogd = {
          enable = true;
          extraConfig = ''
            auth,authpriv.*              -/var/log/auth.log
            kern.*                       -/var/log/kernel.log
            cron.*                       -/var/log/cron.log
            user.*                       -/var/log/user.log
          '';
        };
        prometheus = {
          exporters = {
            node = {
              enable = true;
              enabledCollectors = [ "systemd" ];
              port = 9002;
            };
            nvidia-gpu = {
              enable = builtins.elem "nvidia" config.services.xserver.videoDrivers;
              port = 9835;
            };
          };
        };
      };
    };
}
