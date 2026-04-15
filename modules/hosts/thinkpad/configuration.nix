{ self, inputs, ... }:
{
  flake.nixosModules.thinkpad =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.thinkpadHardwareConfiguration
        self.nixosModules.thinkpadDiskoConfiguration
        self.nixosModules.impermanence
        self.nixosModules.laptopTemplate
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

    };
}
