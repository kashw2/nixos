{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.arr-stack =
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;
          name = "arr-stack";
          nodes.machine =
            { config, ... }:
            {
              virtualisation.memorySize = 4096;
              virtualisation.diskSize = 6144;
              services.prowlarr.enable = true;
              services.sonarr.enable = true;
              services.radarr.enable = true;
              services.bazarr.enable = true;
              services.flaresolverr.enable = true;
            };
          testScript = ''
            machine.wait_for_unit("prowlarr.service")
            machine.wait_for_unit("sonarr.service")
            machine.wait_for_unit("radarr.service")
            machine.wait_for_unit("bazarr.service")
            machine.wait_for_unit("flaresolverr.service")
            machine.wait_for_open_port(9696)
            machine.wait_for_open_port(8989)
            machine.wait_for_open_port(7878)
            machine.wait_for_open_port(6767)
            machine.wait_for_open_port(8191)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9696/ping", timeout=60)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:8989/ping", timeout=60)
            machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:7878/ping", timeout=60)
          '';
        }).config.result;
    };
}
