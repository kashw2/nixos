{ self, inputs, ... }:
{
  flake.wrappers.hyprshade =
    {
      pkgs,
      wlib,
      lib,
      config,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.hyprshade;
        env.HYPRSHADE_CONFIG = pkgs.writeText "hyprshade.toml" ''
          [[shades]]
           name       = "blue-light-filter"
           start_time = "19:00:00"
           end_time   = "06:30:00"
        '';
      };
    };
}
