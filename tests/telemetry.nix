{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mkTelemetryTest =
        role: node: testScript:
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;
          name = "telemetry-${role}";
          nodes.machine =
            { lib, pkgs, ... }:
            {
              imports = [
                self.nixosModules.telemetry
                inputs.sops-nix.nixosModules.sops
                node
              ];

              telemetry.role = role;
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
              systemd.tmpfiles.rules = [ "d /run/secrets 0755 root root - -" ];
            };
          inherit testScript;
        }).config.result;
    in
    {
      packages.telemetry-client =
        mkTelemetryTest "client"
          (
            { config, ... }:
            {
              systemd.tmpfiles.rules = [
                "d /run/secrets/rendered 0755 root root - -"
                "f ${
                  config.sops.templates."opentelemetry-collector.env".path
                } 0400 root root - ONEUPTIME_INGESTION_TOKEN=test"
              ];
            }
          )
          ''
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
            machine.succeed(f"grep -q 'job_name: SMART' {config}")

            machine.wait_for_unit("prometheus-smartctl-exporter.service")
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9633/metrics", timeout=60)
            machine.wait_until_succeeds(
                "journalctl -u opentelemetry-collector.service | grep -q 'Journalctl command'",
                timeout=60,
            )
          '';

      packages.telemetry-host =
        mkTelemetryTest "host"
          {
            virtualisation.memorySize = 4096;
            virtualisation.diskSize = 4096;

            # alloy.nix references networking.defaultGateway.address (for
            # the openwrt scrape target). It defaults to null, which fails
            # eval — provide a stub.
            networking.defaultGateway.address = "192.168.1.1";

            sops.secrets."oneuptime/homelab/ingestion_token" = { };
            systemd.tmpfiles.rules = [
              "d /run/secrets/oneuptime/homelab 0755 root root - -"
              "f /run/secrets/oneuptime/homelab/ingestion_token 0400 root root -"
            ];
          }
          ''
            machine.wait_for_unit("alloy.service")
            machine.wait_for_open_port(12345)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:12345/-/ready", timeout=60)

            config = machine.succeed(
                "systemctl show opentelemetry-collector.service -p ExecStart --value"
                " | grep -o '/nix/store/[^ ]*-config.yaml'"
            ).strip()
            machine.fail(f"grep -q journald {config}")
          '';
    };
}
