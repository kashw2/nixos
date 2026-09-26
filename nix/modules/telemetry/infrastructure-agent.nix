{ self, ... }:
{
  flake.nixosModules.oneuptimeInfrastructureAgent =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.telemetry.agent;
      configPath = "/run/oneuptime-infrastructure-agent/config.json";
      writeConfig = pkgs.writeShellScript "oneuptime-agent-config" ''
        ${lib.getExe pkgs.jq} -n \
          --arg secret_key "$(cat ${
            config.sops.secrets."oneuptime/agent_key/${config.networking.hostName}".path
          })" \
          --arg oneuptime_url "${cfg.url}" \
          '{secret_key: $secret_key, oneuptime_url: $oneuptime_url, proxy_url: ""}' \
          > ${configPath}
      '';
    in
    {

      options.telemetry.agent = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Report host metrics to OneUptime via its infrastructure agent.";
        };
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://oneuptime.media.local";
          description = "Root URL of the OneUptime instance the agent reports to.";
        };
      };

      config = lib.mkIf cfg.enable {

        systemd.services.oneuptime-infrastructure-agent = {
          description = "OneUptime infrastructure agent";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          environment.ONEUPTIME_AGENT_CONFIG_PATH = configPath;
          serviceConfig = {
            RuntimeDirectory = "oneuptime-infrastructure-agent";
            RuntimeDirectoryMode = "0700";
            RuntimeDirectoryPreserve = "restart";
            ExecStartPre = writeConfig;
            ExecStart = "${
              lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.oneuptime-infrastructure-agent
            } run";
            Restart = "always";
            RestartSec = 30;
          };
        };

      };
    };
}
