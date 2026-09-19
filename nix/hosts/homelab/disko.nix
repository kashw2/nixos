{ self, inputs, ... }:
{
  flake.nixosModules.homelabDiskoConfiguration =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices.disk = {
        main = {
          device = "/dev/disk/by-id/ata-KINGSTON_SHSS37A240G_50026B725A024EC8";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                type = "EF02";
                size = "1M";
                priority = 1;
              };
              esp = {
                type = "EF00";
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountOptions = [ "umask=0077" ];
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
