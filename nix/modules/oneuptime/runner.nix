{ self, ... }:
{
  flake.nixosModules.oneuptimeRunner =
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

      config = lib.mkIf cfg.runner.enable {

        oneuptime.runner.settings = lib.mapAttrs (_: lib.mkDefault) {
          ONEUPTIME_URL = "${cfg.httpProtocol}://${cfg.host}";
          PORT = toString cfg.runner.port;
          NODE_ENV = "production";
          LOG_LEVEL = "ERROR";
          DISABLE_TELEMETRY = "true";
          ONEUPTIME_RUNNER_ENABLE_CODE_FIXES = "true";
          ONEUPTIME_RUNNER_ENABLE_RUNBOOKS = "true";
        };

        systemd.services.oneuptime-runner = {
          description = "OneUptime runner";
          after = [ "oneuptime-app.service" ];
          wants = [ "oneuptime-app.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = cfg.runner.settings;
          serviceConfig = {
            User = "oneuptime";
            Group = "oneuptime";
            StateDirectory = "oneuptime-runner";
            EnvironmentFile = config.sops.templates."oneuptime-runner.env".path;
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.oneuptime-runner;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            Restart = "always";
            RestartSec = 10;
          };
        };

      };
    };
}
