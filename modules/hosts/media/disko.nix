{ self, inputs, ... }:
{
  flake.nixosModules.mediaDiskoConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices.disk = {
        main = {
          device = "/dev/disk/by-id/mmc-TWSC_0x1f61e315";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                type = "EF02";
                size = "1M";
                priority = 1;
              };
              ESP = {
                type = "EF00";
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountOptions = [ "umask=0077" ];
                  mountpoint = "/boot";
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
        torrents = {
          device = "/dev/disk/by-id/nvme-KLEVV_CRAS_C910_M.2_NVMe_SSD_4TB_2025041805001281";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "torrents" = {
                      mountpoint = "/mnt/torrents";
                      mountOptions = [
                        "compress=zstd"
                      ];
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
