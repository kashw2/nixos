{ inputs, ... }:
{
  flake.nixosModules.attic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.attic.nixosModules.atticd ];

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

      environment = {
        persistence."/persist".directories = lib.mkIf config.impermanence.enable [
          "/var/lib/atticd"
        ];
        systemPackages = [ inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client ];
      };

      systemd.services.atticd-bootstrap = {
        description = "Create the nixos attic cache if absent";
        wantedBy = [ "multi-user.target" ];
        after = [ "atticd.service" ];
        requires = [ "atticd.service" ];
        path = [
          config.services.atticd.package
          inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client
          pkgs.curl
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
          attic cache info nixos >/dev/null 2>&1 || attic cache create nixos
          attic cache configure nixos --public
        '';
      };
    };
}
