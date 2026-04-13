{ self, inputs, ... }:
{
  flake.nixosModules.home =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.homeHardwareConfiguration
        self.nixosModules.homeDiskoConfiguration
        self.nixosModules.desktopTemplate
        self.nixosModules.keanu
      ];

      networking = {
        hostName = "home";
        networkmanager = {
          enable = true;
          ensureProfiles.profiles = {
            enp10s0 = {
              connection = {
                id = "enp10s0";
                type = "ethernet";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.5";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
            wlp9s0 = {
              connection = {
                id = "wlp9s0";
                type = "wifi";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.5";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
          };
        };
        interfaces = {
          enp10s0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.5";
                prefixLength = 24;
              }
            ];
          };
          wlp9s0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "192.168.1.5";
                prefixLength = 24;
              }
            ];
          };
        };
      };

      hardware = {
        graphics = {
          enable = true;
          extraPackages = [ pkgs.libvdpau-va-gl ];
        };
      };

      services.xserver.videoDrivers = [ "amdgpu" ];

    };
}
