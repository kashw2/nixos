{ self, inputs, ... }:
{
  flake.wrappers.hyprpaper =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper;
        flags."--config" = pkgs.writeText "hyprpaper.conf" ''
          splash = false

          wallpaper {
            monitor =
            path = ${./Background.jpg}
            fit_mode = cover
          }
        '';
      };
    };
}
