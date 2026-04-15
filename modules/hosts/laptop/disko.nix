{ self, inputs, ... }:
{
  flake.nixosModules.laptopDiskoConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices.disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S4EWNG0M218784A";
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
                    # Mounted at /. Wiped on every boot by the
                    # rollback-root initrd service — the live subvolume is
                    # renamed into /old_roots/ and a fresh empty one is
                    # created in its place (see impermanence.nix).
                    "root" = {
                      mountpoint = "/";
                    };
                    # Mounted at /home. Also wiped on every boot; opt-in
                    # state is restored via home-manager impermanence.
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
