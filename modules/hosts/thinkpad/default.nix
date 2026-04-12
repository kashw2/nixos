{ inputs, self, ... }:
{
  flake.nixosConfigurations.thinkpad = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.thinkpad
    ];
  };
}
