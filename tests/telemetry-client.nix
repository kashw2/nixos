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
            { ... }:
            {
              imports = [ self.nixosModules.telemetry ];

              telemetry.role = "client";
              telemetry.agent.enable = false;
            };
          testScript = ''
            machine.wait_for_unit("prometheus-node-exporter.service")
            machine.wait_for_open_port(9002)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9002/metrics", timeout=60)

            machine.fail("systemctl cat alloy.service")
          '';
        }).config.result;
    };
}
