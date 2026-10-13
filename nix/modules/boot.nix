{ self, inputs, ... }:
{
  flake.nixosModules.boot =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config = lib.mkMerge [
        {
          boot = {
            # All machines run the xanmod kernel
            kernelPackages = pkgs.linuxPackages_xanmod_stable;
            kernel.sysctl = {
              "kernel.sysrq" = 1; # Enable SysRQ for rebooting properly during halts
            };
          };
        }

        (lib.mkIf config.isServer {
          boot.loader = {
            systemd-boot = {
              enable = true;
              configurationLimit = 10;
            };
            efi.canTouchEfiVariables = true;
          };
        })

        (lib.mkIf (!config.isServer) {
          boot = {
            loader.grub = {
              enable = true;
              device = "nodev";
              configurationLimit = 5;
              useOSProber = true;
              efiSupport = true;
              efiInstallAsRemovable = true;
            };
            plymouth = {
              enable = true;
              theme = "dotted";
              themePackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-dotted ];
            };
            # Silent boot so kernel/systemd messages don't draw over the splash.
            consoleLogLevel = 3;
            initrd.verbose = false;
            kernelParams = [
              "quiet"
              "udev.log_level=3"
              "systemd.show_status=auto"
            ];
          };

          # The plymouth theme loads frames lazily, so it keeps reading them after
          # switch-root. Its ImageDir points at the initrd's copy of the theme,
          # which isn't otherwise in the system closure.
          system.extraDependencies = [
            config.boot.initrd.systemd.contents."/etc/plymouth/themes".source
          ];
        })
      ];
    };
}
