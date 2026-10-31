{ self, inputs, ... }:
{
  flake.wrappers.hyprlock =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.hyprlock;
        flags."--config" = pkgs.writeText "hyprlock.conf" ''
          background {
            blur_passes=3
            blur_size=4
            brightness=0.800000
            color=rgba(255, 255, 255, 1.0)
            contrast=1.300000
            path=${./Background.jpg}
            vibrancy=0.210000
            vibrancy_darkness=0.000000
          }

          input-field {
            size=250, 50
            dots_size=0.200000
            dots_spacing=0.640000
            font_color=rgba(255, 255, 255, 0.6)
            inner_color=rgba(255, 255, 255, 0)
            outer_color=rgba(255, 255, 255, 0)
            outline_thickness=0
            placeholder_text=<i>Password...</i>
            position=0, 50
            rounding=0
            valign=bottom
          }

          label {
            font_family=JetBrains Mono 10
            font_size=64
            position=0, 16
            text=cmd[update:1000] echo "<b><big> $(date +"%H:%M:%S") </big></b>"
          }

          label {
            font_family=JetBrains Mono 10
            font_size=20
            position=0, -50
            text=Hey <span text_transform="capitalize">$USER</span>
          }

          label {
            font_family=JetBrains Mono 10
            position=0, 30
            text=Type to unlock!
            valign=bottom
          }
        '';
      };
    };
}
