{ self, inputs, ... }:
{
  flake.nixosModules.home =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.homeHardwareConfiguration
        self.nixosModules.homeDiskoConfiguration
        self.nixosModules.impermanence
        self.nixosModules.desktopTemplate
        self.nixosModules.keanu
      ];

      # Values consumed by modules/features/impermanence.nix. The unit
      # name is systemd-escaped: `/` → `-`, and each original `-` in the
      # path becomes `\x2d` (double-backslashed here to survive the
      # nix string parser).
      impermanence = {
        rootDevice = "/dev/disk/by-partlabel/disk-main-root";
        rootDeviceUnit = "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device";
      };

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
