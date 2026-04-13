{ self, inputs, ... }:
{
  flake.nixosModules.serverTemplate =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.environment
      ];

      boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
      };
    };
}
