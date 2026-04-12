{ self, inputs, ... }:
{
  flake.nixosModules.laptopTemplate =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.environment
        self.nixosModules.desktopEnvironment
        self.nixosModules.audio
        self.nixosModules.virtualisation
      ];

      desktopEnvironment.isLaptop = true;
      desktopEnvironment.isDesktop = false;

    };
}
