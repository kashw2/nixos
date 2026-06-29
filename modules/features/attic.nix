{ inputs, ... }:
{
  flake.nixosModules.attic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.attic;
    in
    {
      imports = [ inputs.attic.nixosModules.atticd ];

      options.attic.server.enable = lib.mkEnableOption "the atticd binary cache server (only one host should enable this)";

      config = lib.mkMerge [
        {
          environment.systemPackages = [
            inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client
          ];

          systemd.services.attic-watch-store = {
            description = "Push new Nix store paths to the media attic cache";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = [ config.nix.package ];
            serviceConfig = {
              ExecStart = "${
                lib.getExe' inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client "attic"
              } watch-store nixos";
              Environment = [
                "XDG_CONFIG_HOME=/run"
                "NIX_REMOTE=daemon"
              ];
              Restart = "always";
              RestartSec = "10s";
            };
          };
        }

        (lib.mkIf cfg.server.enable {
          services.atticd = {
            enable = true;
            environmentFile = config.sops.secrets."attic_server_token".path;
            settings = {
              listen = "[::]:8080";
              storage = {
                type = "local";
                path = "/var/lib/atticd/storage";
              };
              chunking = {
                nar-size-threshold = 65536;
                min-size = 16384;
                avg-size = 65536;
                max-size = 262144;
              };
              garbage-collection = {
                interval = "1 hour";
                default-retention-period = "2 weeks";
              };
            };
          };

          networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];

          systemd.services.atticd.serviceConfig.DynamicUser = lib.mkForce false;

          users.users.atticd = {
            isSystemUser = true;
            group = "atticd";
            home = "/var/lib/atticd";
          };
          users.groups.atticd = { };

          systemd.services.atticd-bootstrap = {
            description = "Create the nixos attic cache if absent";
            wantedBy = [ "multi-user.target" ];
            after = [ "atticd.service" ];
            requires = [ "atticd.service" ];
            path = [
              config.services.atticd.package
              inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client
              pkgs.curl
              pkgs.sqlite
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              EnvironmentFile = config.sops.secrets."attic_server_token".path;
            };
            script = ''
              set -euo pipefail
              export HOME="$(mktemp -d)"
              until curl -sf -o /dev/null http://localhost:8080; do sleep 1; done
              token="$(atticadm -f ${lib.elemAt (lib.splitString " " config.systemd.services.atticd.serviceConfig.ExecStart) 2} make-token --sub bootstrap --validity '1h' \
                --pull 'nixos' --push 'nixos' --create-cache 'nixos' \
                --configure-cache 'nixos' --configure-cache-retention 'nixos')"
              attic login local http://localhost:8080 "$token"
              if ! attic cache info nixos >/dev/null 2>&1; then
                attic cache create nixos
                attic cache configure nixos --public
              fi
              # Inject stable signing key so trusted-public-keys never needs to change
              sqlite3 /var/lib/atticd/server.db \
                "UPDATE cache SET keypair = '$(cat ${
                  config.sops.secrets."attic_signing_key".path
                })' WHERE name = 'nixos'"
            '';
          };
        })
      ];
    };
}
