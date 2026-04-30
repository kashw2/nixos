{ inputs, self, ... }:
{
  flake.nixosConfigurations.homelab = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.homelab
    ];
  };
}
