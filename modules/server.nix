{ self, inputs, ... }:
{
  flake.nixosModules.serverTemplate =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.environment
      ];

      isServer = true;
      isDesktop = false;
      isLaptop = false;

      boot = {
        loader.systemd-boot.enable = true;
        loader.systemd-boot.configurationLimit = 10;
        loader.efi.canTouchEfiVariables = true;
      };
    };
}
