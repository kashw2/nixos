{ inputs, self, ... }:
{
  flake.nixosConfigurations.media = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.media
    ];
  };
}
