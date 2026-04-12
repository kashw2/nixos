{ self, inputs, ... }:
{
  flake.nixosModules.virtualisation =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      virtualisation = {
        docker.enable = true;
        podman.enable = true;
        spiceUSBRedirection.enable = true;
      };

      services = {
        spice-vdagentd.enable = true;
        spice-webdavd.enable = true;
        spice-autorandr.enable = true;
      };

      environment.systemPackages =
        [ ]
        ++ lib.optionals config.virtualisation.docker.enable [
          pkgs.docker
          pkgs.docker-compose
        ]
        ++ lib.optionals config.virtualisation.podman.enable [
          pkgs.podman
          pkgs.podman-compose
        ]
        ++ lib.optionals (config.virtualisation.podman.enable || config.virtualisation.docker.enable) [
          pkgs.syft
          pkgs.grype
          pkgs.dive
        ]
        ++ lib.optionals config.virtualisation.spiceUSBRedirection.enable [ pkgs.spice-vdagent ];
    };
}
