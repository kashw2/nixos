{ self, ... }:
{
  flake.nixosModules.oneuptime =
    { config, lib, ... }:
    {

      imports = [
        self.nixosModules.oneuptimeApp
        self.nixosModules.oneuptimeProbe
        self.nixosModules.oneuptimeRunner
      ];

      options.oneuptime = {
        enable = lib.mkEnableOption "the self-hosted OneUptime stack";

        host = lib.mkOption {
          type = lib.types.str;
          default = "oneuptime.${config.networking.hostName}.local";
          description = "Public hostname OneUptime serves on, used as HOST.";
        };

        httpProtocol = lib.mkOption {
          type = lib.types.enum [
            "http"
            "https"
          ];
          default = "http";
          description = "Scheme OneUptime is reached over, used as HTTP_PROTOCOL.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 3002;
          description = "Loopback port the OneUptime app listens on.";
        };

        probe = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = config.oneuptime.enable;
            description = "Run a OneUptime monitoring probe on this host.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 3874;
            description = "Loopback port the probe listens on.";
          };
          netflowPort = lib.mkOption {
            type = lib.types.port;
            default = 2055;
            description = "UDP port the probe accepts NetFlow v5 records from network devices on.";
          };
          syslogPort = lib.mkOption {
            type = lib.types.port;
            default = 514;
            description = "UDP port the probe accepts syslog from network devices on.";
          };
          settings = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Environment passed to the probe unit.";
          };
        };

        runner = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Run the OneUptime runbook and code-fix runner on this host.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 3876;
            description = "Loopback port the runner listens on.";
          };
          settings = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Environment passed to the runner unit.";
          };
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Environment passed to the OneUptime app and migration units.";
        };
      };

      config = lib.mkIf config.oneuptime.enable {
        users = {
          users.oneuptime = {
            isSystemUser = true;
            group = "oneuptime";
            description = "OneUptime";
          };
          groups.oneuptime = { };
        };

        assertions = [
          {
            assertion = config.services.postgresql.enable;
            message = "oneuptime.enable requires services.postgresql.enable";
          }
          {
            assertion = config.services.clickhouse.enable;
            message = "oneuptime.enable requires services.clickhouse.enable";
          }
          {
            assertion = config.services.redis.servers ? oneuptime;
            message = "oneuptime.enable requires services.redis.servers.oneuptime";
          }
        ];
      };

    };
}
