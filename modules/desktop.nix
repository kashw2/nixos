{ self, inputs, ... }:
{
  flake.nixosModules.desktopTemplate =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.environment
        self.nixosModules.desktopEnvironment
        self.nixosModules.audio
        self.nixosModules.virtualisation
      ];

      desktopEnvironment.isLaptop = false;
      desktopEnvironment.isDesktop = true;

    };
}
