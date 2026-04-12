{ self, inputs, ... }:
{
  flake.nixosModules.serverTemplate =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.environment
      ];

    };
}
