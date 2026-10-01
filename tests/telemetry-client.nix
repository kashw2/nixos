{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.telemetry-client =
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;
          name = "telemetry-client";
          nodes.machine =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            {
              imports = [
                self.nixosModules.telemetry
                inputs.sops-nix.nixosModules.sops
              ];

              telemetry.role = "client";
              telemetry.agent.enable = false;

              sops = {
                age.keyFile = "/dev/null";
                defaultSopsFile = pkgs.writeText "fake.yaml" "{}";
                validateSopsFiles = false;
                useSystemdActivation = false;
                templates."snmpd.conf".content = "rouser test priv";
                templates."opentelemetry-collector.env".content = "ONEUPTIME_INGESTION_TOKEN=test";
              };
              system.activationScripts.setupSecrets = lib.mkForce "";
              systemd.tmpfiles.rules = [
                "d /run/secrets 0755 root root - -"
                "d /run/secrets/rendered 0755 root root - -"
                "f ${
                  config.sops.templates."opentelemetry-collector.env".path
                } 0400 root root - ONEUPTIME_INGESTION_TOKEN=test"
              ];
            };
          testScript = ''
            machine.wait_for_unit("prometheus-node-exporter.service")
            machine.wait_for_open_port(9002)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9002/metrics", timeout=60)

            machine.fail("systemctl cat alloy.service")

            machine.wait_for_unit("opentelemetry-collector.service")
            config = machine.succeed(
                "systemctl show opentelemetry-collector.service -p ExecStart --value"
                " | grep -o '/nix/store/[^ ]*-config.yaml'"
            ).strip()
            machine.succeed(f"grep -q journald {config}")
            machine.wait_until_succeeds(
                "journalctl -u opentelemetry-collector.service | grep -q 'Journalctl command'",
                timeout=60,
            )
          '';
        }).config.result;
    };
}
