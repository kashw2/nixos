{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.telemetry-client =
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;
          name = "telemetry-client";
          nodes.machine =
            { ... }:
            {
              imports = [ self.nixosModules.telemetry ];

              features.telemetry.role = "client";
            };
          testScript = ''
            machine.wait_for_unit("prometheus-node-exporter.service")
            machine.wait_for_open_port(9002)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9002/metrics", timeout=60)

            # A client must not run the LGTM stack
            for service in ["grafana", "loki", "mimir", "tempo", "alloy"]:
                machine.fail(f"systemctl cat {service}.service")
          '';
        }).config.result;
    };
}
