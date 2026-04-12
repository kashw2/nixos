{ self, inputs, ... }:
{
  flake.nixosModules.thinkpad =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.thinkpadHardwareConfiguration
        self.nixosModules.thinkpadDiskoConfiguration
        self.nixosModules.laptopTemplate
        self.nixosModules.keanu
      ];

      networking = {
        hostName = "thinkpad";
        defaultGateway = {
          address = "192.168.1.1";
          interface = "wlp4s0";
        };
        networkmanager = {
          enable = true;
          ensureProfiles.profiles = {
            wlp4s0 = {
              connection = {
                id = "wlp4s0";
                interface-name = "wlp4s0";
                type = "wifi";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.9";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
          };
        };
        interfaces = {
          wlp4s0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.9";
                prefixLength = 24;
              }
            ];
          };
        };
      };

      boot = {
        loader.grub = {
          enable = true;
          configurationLimit = 10;
          useOSProber = true;
          efiSupport = true;
          efiInstallAsRemovable = true;
        };
      };

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Experimental = true;
            };
          };
        };
        graphics = {
          enable = true;
          extraPackages = [ pkgs.libvdpau-va-gl ];
        };
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
