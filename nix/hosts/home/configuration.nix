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

      impermanence.enable = false;

      # DP-3's preferred mode is 4K; pin it to 1080p so plymouth renders the
      # 1080p splash frames without upscaling every frame.
      boot.kernelParams = [ "video=DP-3:1920x1080@60" ];

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
                address1 = "192.168.1.15";
                gateway = "192.168.1.1";
                method = "auto";
              };
            };
          };
        };
      };

      # Leave a quarter of the 9950X3D free during builds: pin the daemon (and
      # every build it spawns) to physical cores 0-11 plus their SMT siblings,
      # and size each build's NIX_BUILD_CORES to match.
      nix.settings.cores = 24;
      systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "0-11,16-27";

      hardware = {
        graphics = {
          enable = true;
          extraPackages = [ pkgs.libvdpau-va-gl ];
        };
      };
    };
}
