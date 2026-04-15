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

      isDesktop = true;

      boot.loader.grub = {
        enable = true;
        configurationLimit = 10;
        useOSProber = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
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
