{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.telemetry-host =
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

              telemetry.role = "host";
              telemetry.agent.enable = false;
              virtualisation.memorySize = 4096;
              virtualisation.diskSize = 4096;

              # alloy.nix references networking.defaultGateway.address (for
              # the openwrt scrape target). It defaults to null, which fails
              # eval — provide a stub.
              networking.defaultGateway.address = "192.168.1.1";

              sops = {
                age.keyFile = "/dev/null";
                defaultSopsFile = pkgs.writeText "fake.yaml" "{}";
                validateSopsFiles = false;
                useSystemdActivation = false;
                secrets = {
                  "oneuptime/ingestion_token" = { };
                };
                templates."snmpd.conf".content = "rouser test priv";
              };
              system.activationScripts.setupSecrets = lib.mkForce "";
              systemd.tmpfiles.rules = [
                "d /run/secrets 0755 root root - -"
                "d /run/secrets/oneuptime 0755 root root - -"
                "f /run/secrets/oneuptime/ingestion_token 0400 root root -"
              ];
            };
          testScript = ''
            machine.wait_for_unit("alloy.service")
            machine.wait_for_open_port(12345)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:12345/-/ready", timeout=60)
          '';
        }).config.result;
    };
}
