{ self, ... }:
{
  flake.nixosModules.qemu =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      fallback = {
        memorySize = 2048;
        cores = 2;
        gpu = false;
      };

      specs = {
        home = {
          memorySize = 8096;
          cores = 10;
          gpu = true;
        };
        laptop = {
          memorySize = 8096;
          cores = 8;
          gpu = true;
        };
      };

      spec = specs.${config.networking.hostName} or fallback;

      qemuOptions = lib.optionals spec.gpu [
        "-vga none"
        "-device virtio-gpu-gl-pci,xres=1920,yres=1080"
        "-display gtk,gl=on"
      ];

      hyprlandPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.wrap {
        isLaptop = false;
        isDesktop = false;
      };
    in
    {
      virtualisation.vmVariant = {
        virtualisation = {
          inherit (spec) memorySize cores;
          diskSize = 6384;
          graphics = !config.isServer;
          qemu.options = qemuOptions;
        };
        # The host monitor rules name physical outputs this guest does not have.
        programs.hyprland.package = lib.mkIf (!config.isServer) (lib.mkForce hyprlandPackage);
        # virgl exposes no alpha-capable EGL config, so Qt renders opaque and kitty dies.
        environment.sessionVariables = lib.mkIf (!config.isServer) {
          QT_QUICK_BACKEND = "software";
          LIBGL_ALWAYS_SOFTWARE = "1";
        };
        # Hyprland autostarts kitty with --directory ~/nixos, which a fresh guest lacks.
        systemd.tmpfiles.rules = [ "d /home/keanu/nixos 0755 keanu keanu -" ];
        boot.resumeDevice = lib.mkForce "";
        users.users.keanu = {
          hashedPasswordFile = lib.mkForce null;
          initialPassword = "nixos";
        };
      };

      virtualisation.vmVariantWithBootLoader = {
        virtualisation = {
          inherit (spec) memorySize cores;
          diskSize = 6384;
          graphics = !config.isServer;
          qemu.options = qemuOptions;
        };
        # The host monitor rules name physical outputs this guest does not have.
        programs.hyprland.package = lib.mkIf (!config.isServer) (lib.mkForce hyprlandPackage);
        # virgl exposes no alpha-capable EGL config, so Qt renders opaque and kitty dies.
        environment.sessionVariables = lib.mkIf (!config.isServer) {
          QT_QUICK_BACKEND = "software";
          LIBGL_ALWAYS_SOFTWARE = "1";
        };
        # Hyprland autostarts kitty with --directory ~/nixos, which a fresh guest lacks.
        systemd.tmpfiles.rules = [ "d /home/keanu/nixos 0755 keanu keanu -" ];
        boot.resumeDevice = lib.mkForce "";
        users.users.keanu = {
          hashedPasswordFile = lib.mkForce null;
          initialPassword = "nixos";
        };
      };
    };
}
