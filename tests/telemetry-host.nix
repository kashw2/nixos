{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.telemetry-host =
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;
          name = "telemetry-host";
          nodes.machine =
            { lib, pkgs, ... }:
            {
              imports = [
                self.nixosModules.telemetry
                inputs.sops-nix.nixosModules.sops
              ];

              features.telemetry.role = "host";
              virtualisation.memorySize = 4096;
              virtualisation.diskSize = 4096;

              # alloy.nix references networking.defaultGateway.address (for
              # the openwrt scrape target). It defaults to null, which fails
              # eval — provide a stub.
              networking.defaultGateway.address = "192.168.1.1";

              # Stand up the sops options namespace so grafana.nix's
              # `config.sops.secrets."grafana_secret_key".path` resolves,
              # but bypass actual sops-nix decryption (no real age key in
              # the test). The secret file is materialised by tmpfiles
              # before grafana starts.
              sops = {
                age.keyFile = "/dev/null";
                defaultSopsFile = pkgs.writeText "fake.yaml" "{}";
                validateSopsFiles = false;
                useSystemdActivation = false;
                secrets.grafana_secret_key = {
                  owner = "grafana";
                  group = "grafana";
                };
              };
              system.activationScripts.setupSecrets = lib.mkForce "";
              systemd.tmpfiles.rules = [
                "d /run/secrets 0755 root root - -"
                "f /run/secrets/grafana_secret_key 0440 grafana grafana - test-secret-key-value"
              ];
            };
          testScript = ''
            machine.wait_for_unit("grafana.service")
            machine.wait_for_unit("loki.service")
            machine.wait_for_unit("mimir.service")
            machine.wait_for_unit("tempo.service")
            machine.wait_for_unit("alloy.service")
            machine.wait_for_open_port(3000)
            machine.wait_for_open_port(3100)
            machine.wait_for_open_port(3200)
            machine.wait_for_open_port(9009)
            machine.wait_for_open_port(12345)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:3000/api/health", timeout=60)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:3100/ready", timeout=60)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9009/ready", timeout=60)
          '';
        }).config.result;
    };
}
