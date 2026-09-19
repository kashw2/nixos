{ inputs, self, ... }:
{
  flake.nixosConfigurations.home = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.home
    ];
  };
}
