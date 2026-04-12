{ self, inputs, ... }:
{
  flake.nixosModules.homeDiskoConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices.disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21BNXAGA02668X";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                type = "EF02"; # for grub MBR
                size = "1M";
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
                size = "12G";
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
}
