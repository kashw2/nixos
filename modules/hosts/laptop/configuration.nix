{ self, inputs, ... }:
{
  flake.nixosModules.laptop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      imports = [
        self.nixosModules.laptopHardwareConfiguration
        self.nixosModules.laptopDiskoConfiguration
        self.nixosModules.laptopTemplate
        self.nixosModules.impermanence
        self.nixosModules.keanu
      ];

      # Values consumed by modules/features/impermanence.nix. The unit
      # name is systemd-escaped: `/` → `-`, and each original `-` in the
      # path becomes `\x2d` (double-backslashed here to survive the
      # nix string parser).
      impermanence = {
        enable = true;
        rootDevice = "/dev/disk/by-partlabel/disk-main-root";
        rootDeviceUnit = "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device";
      };

      networking = {
        hostName = "laptop";
        defaultGateway = {
          address = "192.168.1.1";
          interface = "enp4s0f1";
        };
        networkmanager = {
          enable = true;
          ensureProfiles.profiles = {
            enp4s0f1 = {
              connection = {
                id = "enp4s0f1";
                interface-name = "enp4s0f1";
                type = "ethernet";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.6";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
            wlp3s0 = {
              connection = {
                id = "wlp3s0";
                interface-name = "wlp3s0";
                type = "wifi";
                autoconnect = true;
              };
              ipv4 = {
                address1 = "192.168.1.16";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
          };
        };
      };

      hardware = {
        # nouveau (not proprietary) so the Pascal GTX 1050 can D3cold when idle.
        # Slow reclocking; offload is DRI_PRIME=1.
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

      services.xserver.videoDrivers = [ "nouveau" ];

      # Colon-free iGPU alias; AQ_DRM_DEVICES is colon-separated so by-path names break it.
      services.udev.extraRules = ''
        KERNEL=="card*", SUBSYSTEM=="drm", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
      '';

      # Pin the compositor to the iGPU so the dGPU stays idle. Session env, not
      # hl.env(): aquamarine reads it before the config parses.
      environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/igpu";

    };
}
