{ self, ... }:
{
  flake.nixosModules.oneuptimeProbe =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.oneuptime;
    in
    {

      config = lib.mkIf cfg.probe.enable {

        oneuptime.probe.settings = lib.mapAttrs (_: lib.mkDefault) {
          ONEUPTIME_URL = "${cfg.httpProtocol}://${cfg.host}";
          PORT = toString cfg.probe.port;
          NODE_ENV = "production";
          LOG_LEVEL = "ERROR";
          DISABLE_TELEMETRY = "true";
          PROBE_ALLOW_PRIVATE_NETWORK_MONITORS = "true";
          PROBE_MONITORING_WORKERS = "5";
          PROBE_MONITOR_FETCH_LIMIT = "10";
          PROBE_SYNTHETIC_MONITOR_CHROMIUM_SANDBOX_ENABLED = "false";
        };

        systemd.services.oneuptime-probe = {
          description = "OneUptime monitoring probe";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = cfg.probe.settings;
          serviceConfig = {
            Type = "simple";
            User = "oneuptime";
            Group = "oneuptime";
            StateDirectory = "oneuptime-probe";
            WorkingDirectory = "/var/lib/oneuptime-probe";
            Environment = "HOME=/var/lib/oneuptime-probe";
            EnvironmentFile = config.sops.templates."oneuptime-probe.env".path;
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.oneuptime-probe;
            CapabilityBoundingSet = [
              "CAP_NET_BIND_SERVICE"
              "CAP_NET_RAW"
            ];
            AmbientCapabilities = [
              "CAP_NET_BIND_SERVICE"
              "CAP_NET_RAW"
            ];
            NoNewPrivileges = true;
            Restart = "always";
            RestartSec = 10;
          };
        };

      };
    };
}
