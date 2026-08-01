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

      isLaptop = true;
      isDesktop = false;
      isServer = false;

      boot.loader.grub = {
        enable = true;
        device = "nodev";
        configurationLimit = 5;
        useOSProber = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.symbols-only
      ];

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

      services = {
        gvfs.enable = true; # Nautilus requires this for certain locations (Trash etc)
        tlp = {
          enable = true;
          settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
            PCIE_ASPM_ON_BAT = "powersupersave";
            SATA_LINKPWR_ON_BAT = "min_power";
            WIFI_PWR_ON_BAT = "on";
            USB_AUTOSUSPEND = 1;
          };
        };
        power-profiles-daemon.enable = false;
      };

    };
}
