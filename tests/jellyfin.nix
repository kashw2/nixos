{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.jellyfin =
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;
          name = "jellyfin";
          nodes.machine =
            { ... }:
            {
              imports = [ self.nixosModules.jellyfin ];
              virtualisation.memorySize = 2048;
              virtualisation.diskSize = 4096;
            };
          testScript = ''
            machine.wait_for_unit("jellyfin.service")
            machine.wait_for_open_port(8096)
            machine.wait_until_succeeds(
              "curl --fail --silent http://localhost:8096/System/Info/Public",
              timeout=60,
            )
          '';
        }).config.result;
    };
}
