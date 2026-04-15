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
        extraPackages = [
          pkgs.networkmanager
          pkgs.bluez
          pkgs.jq
          pkgs.curl
          pkgs.upower
          pkgs.power-profiles-daemon
        ]
        ++ lib.optionals (config.isLaptop) [
          pkgs.brightnessctl
        ];
        flags."-p" = ./quickshell;
      };
    };
}
