{ self, inputs, ... }:
{
  flake.wrappers.quickshell =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
        extraPackages = [
          pkgs.networkmanager
          pkgs.bluez
          pkgs.jq
          pkgs.brightnessctl
          pkgs.curl
          pkgs.upower
          pkgs.power-profiles-daemon
        ];
        flags."-p" = ./shell.qml;
      };
    };
}
