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
        self.nixosModules.homelabDistributedBuilder
        self.nixosModules.macminiDistributedBuilder
        self.nixosModules.buildboxDistributedBuilder
      ];

      nix.distributedBuilds = true;
    };
}
