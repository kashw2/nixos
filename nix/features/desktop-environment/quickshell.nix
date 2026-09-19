{ self, inputs, ... }:
{
  flake.wrappers.quickshell =
    {
      pkgs,
      wlib,
      lib,
      config,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      options = {
        isDesktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        isLaptop = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      config = {
        package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
        runtimePkgs = [
          pkgs.networkmanager
          pkgs.bluez
          pkgs.jq
          pkgs.curl
          pkgs.upower
          pkgs.pipewire
          pkgs.playerctl
          pkgs.fd
          pkgs.chroma
          pkgs.wl-clipboard
          pkgs.systemd
        ]
        ++ lib.optionals (config.isLaptop) [
          pkgs.brightnessctl
        ];
        flags."-p" = ./quickshell;
        env.QS_WALLPAPER = "${./Background.jpg}";
        env.QS_LOCK_CMD = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
      };
    };
}
