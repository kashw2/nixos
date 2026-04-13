{ self, inputs, ... }:
{
  flake.nixosModules.distributedBuilds =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      modules = [
        self.nixosModules.buildboxDistributedBuilder
      ];
      nix.distributedBuilds = true;
    };
}
