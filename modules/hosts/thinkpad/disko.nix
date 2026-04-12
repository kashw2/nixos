{ self, inputs, ... }:
{
  flake.nixosModules.thinkpadDiskoConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = "/dev/disk/by-id/ata-INTEL_SSDSCKJF180A5L_CVTQ607003DM180D";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  size = "1M";
                  type = "EF02"; # for grub MBR
                  priority = 1; # Needs to be first partition
                };
                esp = {
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                  };
                };
                swap = {
                  size = "6G";
                  content = {
                    type = "swap";
                    resumeDevice = true;
                  };
                };
                root = {
                  size = "100%";
                  content = {
                    type = "btrfs";
                    subvolumes = {
                      "root" = {
                        mountpoint = "/";
                      };
                      "nix" = {
                        mountpoint = "/nix";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "home" = {
                        mountpoint = "/home";
                        mountOptions = [ "compress=zstd" ];
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };

    };
}
