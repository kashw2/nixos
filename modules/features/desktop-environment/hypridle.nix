{ self, inputs, ... }:
{
  flake.wrappers.hypridle =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = inputs.hypridle.packages.${pkgs.stdenv.hostPlatform.system}.hypridle;
        flags."--config" = pkgs.writeText "hypridle.conf" ''
          general {
            ignore_dbus_inhibit=false
          }

          listener {
            on-timeout=${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock}
            timeout=600
          }

          listener {
            on-timeout=${lib.getExe' pkgs.systemd "systemctl"} suspend
            timeout=1000
          }
        '';
      };
    };
}
