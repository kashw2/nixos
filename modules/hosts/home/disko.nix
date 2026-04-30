{ self, inputs, ... }:
{
  flake.nixosModules.homeDiskoConfiguration =
    { pkgs, lib, config, ... }:
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
                    # Mounted at /. When impermanence.enable = true this
                    # subvolume is wiped on every boot by the
                    # rollback-root initrd service — the live subvolume is
                    # renamed into /old_roots/ and a fresh empty one is
                    # created in its place (see impermanence.nix).
                    "root" = {
                      mountpoint = "/";
                    };
                    # Mounted at /home. Also wiped on every boot when
                    # impermanence is enabled; opt-in state is restored
                    # via home-manager impermanence.
                    "home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  }
                  // lib.optionalAttrs config.impermanence.enable {
                    # Explicit opt-in state lives here and is bind-mounted
                    # back into / by the impermanence module.
                    "persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    # Keep the journal across reboots. Separate subvolume
                    # so it doesn't flow through the impermanence bind.
                    "log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
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
