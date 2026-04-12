{ self, inputs, ... }:
{
  flake.nixosModules.laptop =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.laptopHardwareConfiguration
        self.nixosModules.laptopDiskoConfiguration
        self.nixosModules.laptopTemplate
        self.nixosModules.keanu
      ];

      networking = {
        hostName = "laptop";
        defaultGateway = {
          address = "192.168.1.1";
          interface = "enp4s0f1";
        };
        networkmanager = {
          enable = true;
          ensureProfiles.profiles = {
            enp4s0f1 = {
              connection = {
                id = "enp4s0f1";
                interface-name = "enp4s0f1";
                type = "ethernet";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.6";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
            wlp3s0 = {
              connection = {
                id = "wlp3s0";
                interface-name = "wlp3s0";
                type = "wifi";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.6";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
          };
        };
        interfaces = {
          enp4s0f1 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.6";
                prefixLength = 24;
              }
            ];
          };
          wlp3s0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.6";
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
        nvidia = {
          open = false;
          powerManagement.enable = false;
          powerManagement.finegrained = false;
          prime = {
            intelBusId = "PCI:00:02:0";
            nvidiaBusId = "PCI:01:00:0";
          };
        };
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

      services.xserver.videoDrivers = [ "nvidia" ];

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
