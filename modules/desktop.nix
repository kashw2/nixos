{ self, inputs, ... }:
{
  flake.nixosModules.desktopTemplate =
    { config, pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.environment
        self.nixosModules.desktopEnvironment
        self.nixosModules.audio
        self.nixosModules.virtualisation
      ];

      isDesktop = true;

      boot.loader.grub = {
        enable = true;
        configurationLimit = 10;
        useOSProber = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        # Dual BIOS+EFI: point at the whole disk so GRUB can write to the
        # EF02 partition allocated in each host's disko config.
        devices = [ config.disko.devices.disk.main.device ];
      };

      fonts.packages = [
        pkgs.jetbrains-mono
      ]
      ++ (builtins.filter lib.isDerivation (builtins.attrValues pkgs.nerd-fonts));

      xdg = {
        mime = {
          enable = true;
          addedAssociations = {
            "text/html" = "firefox-devedition.desktop";
            "x-scheme-handler/http" = "firefox-devedition.desktop";
            "x-scheme-handler/https" = "firefox-devedition.desktop";
            "x-scheme-handler/about" = "firefox-devedition.desktop";
            "x-scheme-handler/unknown" = "firefox-devedition.desktop";
          };
          defaultApplications = {
            "text/html" = "firefox-devedition.desktop";
            "x-scheme-handler/http" = "firefox-devedition.desktop";
            "x-scheme-handler/https" = "firefox-devedition.desktop";
            "x-scheme-handler/about" = "firefox-devedition.desktop";
            "x-scheme-handler/unknown" = "firefox-devedition.desktop";
          };
        };
      };

    };
}
