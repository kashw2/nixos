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
      imports = [
        self.nixosModules.homelabDistributedBuilder
        self.nixosModules.macminiDistributedBuilder
        self.nixosModules.buildboxDistributedBuilder
      ];

      nix.distributedBuilds = true;
    };
}
