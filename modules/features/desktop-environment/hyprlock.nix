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
        package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
        flags."--config" = pkgs.writeText "hyprlock.conf" ''
          background {
            monitor=
            blur_passes=3
            blur_size=4
            brightness=0.800000
            color=rgba(255, 255, 255, 1.0)
            contrast=1.300000
            noise=0.011700
            path=${./Background.jpg}
            vibrancy=0.210000
            vibrancy_darkness=0.000000
          }

          input-field {
            monitor=
            size=250, 50
            dots_center=true
            dots_size=0.200000
            dots_spacing=0.640000
            fade_on_empty=true
            font_color=rgba(255, 255, 255, 0.6)
            halign=center
            hide_input=false
            inner_color=rgba(255, 255, 255, 0)
            outer_color=rgba(255, 255, 255, 0)
            outline_thickness=0
            placeholder_text=<i>Password...</i>
            position=0, 50
            rounding=0
            valign=bottom
          }

          label {
            monitor=
            color=rgba(255, 255, 255, 1.0)
            font_family=JetBrains Mono Nerd Font 10
            font_size=64
            halign=center
            position=0, 16
            text=cmd[update:1000] echo "<b><big> $(date +"%H:%M:%S") </big></b>"
            valign=center
          }

          label {
            monitor=
            color=rgba(255, 255, 255, 1.0)
            font_family=JetBrains Mono Nerd Font 10
            font_size=20
            halign=center
            position=0, -50
            text=Hey <span text_transform="capitalize">$USER</span>
            valign=center
          }

          label {
            monitor=
            color=rgba(255, 255, 255, 1.0)
            font_family=JetBrains Mono Nerd Font 10
            font_size=16
            halign=center
            position=0, 30
            text=Type to unlock!
            valign=bottom
          }
        '';
      };
    };
}
