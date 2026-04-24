{ self, inputs, ... }:
{
  flake.wrappers.hyprland =
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
        # Having both isLaptop and isDesktop as options allows us to let `nix run` be invoked on this package without applying it's own monitor configuration
        isLaptop = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        isDesktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      config = {
        package = pkgs.hyprland;
        # nix-wrapper-modules doesn't forward passthru from the original package,
        # so we must re-declare providedSessions even though upstream Hyprland sets it.
        binName = "start-hyprland";
        exePath = "bin/start-hyprland";
        passthru.mainProgram = "start-hyprland";
        passthru.providedSessions = [ "hyprland" ];
        filesToPatch = [
          "share/applications/*.desktop"
          "share/wayland-sessions/*.desktop"
        ];
        extraPackages = [ pkgs.rose-pine-hyprcursor ];
        addFlag =
          let
            monitorConfiguration =
              if config.isLaptop then
                "monitor=eDP-1,1920x1080@60,0x0,1"
              else if config.isDesktop then
                ''
                  monitor=HDMI-A-1,1920x1080@60,1920x0,1
                  monitor=DP-3,1920x1080@60,0x0,1
                ''
              else
                ''
                  monitor=,1920x1080@60,0x0,1
                '';
          in
          [
            "--"
            "--config"
            (pkgs.writeText "hyprland.conf" ''
              exec-once=${lib.getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target
              exec-once=${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper}
              exec-once=${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hypridle}
              exec-once=${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} store
              exec-once=${
                lib.getExe (
                  self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell.wrap {
                    inherit (config) isDesktop isLaptop;
                  }
                )
              }
              animations {
                bezier=easeOutQuint,   0.23, 1,    0.32, 1
                bezier=easeInOutCubic, 0.65, 0.05, 0.36, 1
                bezier=linear,         0,    0,    1,    1
                bezier=almostLinear,   0.5,  0.5,  0.75, 1
                bezier=quick,          0.15, 0,    0.1,  1
                animation=global,        1,     10,    default
                animation=border,        1,     5.39,  easeOutQuint
                animation=windows,       1,     4.79,  easeOutQuint
                animation=windowsIn,     1,     4.1,   easeOutQuint, popin 87%
                animation=windowsOut,    1,     1.49,  linear,       popin 87%
                animation=fadeIn,        1,     1.73,  almostLinear
                animation=fadeOut,       1,     1.46,  almostLinear
                animation=fade,          1,     3.03,  quick
                animation=layers,        1,     3.81,  easeOutQuint
                animation=layersIn,      1,     4,     easeOutQuint, fade
                animation=layersOut,     1,     1.5,   linear,       fade
                animation=fadeLayersIn,  1,     1.79,  almostLinear
                animation=fadeLayersOut, 1,     1.39,  almostLinear
                animation=workspaces,    1,     1.94,  almostLinear, fade
                animation=workspacesIn,  1,     1.21,  almostLinear, fade
                animation=workspacesOut, 1,     1.94,  almostLinear, fade
                animation=zoomFactor,    1,     7,     quick
                animation=borderangle,   1,     70,   linear,       loop
                enabled=true
              }

              bind=CTRLALT, p, exec, ${lib.getExe pkgs.grim} -g "$( ${lib.getExe pkgs.slurp} )" - | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}
              bind=, INSERT, exec, ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kitty}
              bind=SUPER, M, exec, ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.rofi} -show drun
              bind=SUPER SHIFT, R, forcerendererreload
              bind=SUPER SHIFT, Q, killactive,
              bind=SUPER, F12, exit,
              bind=SUPER, S, togglefloating,
              bind=SUPER, F, fullscreen
              bind=SUPER, P, pseudo,
              bind=SUPER, left, movefocus, l
              bind=SUPER, right, movefocus, r
              bind=SUPER, up, movefocus, u
              bind=SUPER, down, movefocus, d
              bind=SUPER, 1, workspace, 1
              bind=SUPER, 2, workspace, 2
              bind=SUPER, 3, workspace, 3
              bind=SUPER, 4, workspace, 4
              bind=SUPER, 5, workspace, 5
              bind=SUPER, 6, workspace, 6
              bind=SUPER, 7, workspace, 7
              bind=SUPER, 8, workspace, 8
              bind=SUPER, 9, workspace, 9
              bind=SUPER, 0, workspace, 10
              bind=SUPER SHIFT, 1, movetoworkspace, 1
              bind=SUPER SHIFT, 2, movetoworkspace, 2
              bind=SUPER SHIFT, 3, movetoworkspace, 3
              bind=SUPER SHIFT, 4, movetoworkspace, 4
              bind=SUPER SHIFT, 5, movetoworkspace, 5
              bind=SUPER SHIFT, 6, movetoworkspace, 6
              bind=SUPER SHIFT, 7, movetoworkspace, 7
              bind=SUPER SHIFT, 8, movetoworkspace, 8
              bind=SUPER SHIFT, 9, movetoworkspace, 9
              bind=SUPER SHIFT, 0, movetoworkspace, 10
              bind=SUPER, mouse_down, workspace, e+1
              bind=SUPER, mouse_up, workspace, e-1

              ${lib.optionalString config.isLaptop ''
                bindel=,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
                bindel=,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
                bindel=,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
                bindel=,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
                bindel=,XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} -e4 -n2 set 5%+
                bindel=,XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} -e4 -n2 set 5%-
              ''}

              bindm=SUPER, mouse:272, movewindow
              bindm=SUPER, mouse:273, resizewindow

              decoration {
                blur {
                  enabled=true
                  passes=4
                  size=6
                  vibrancy=0.169600
                }

                active_opacity=1.000000
                inactive_opacity=1.000000
                rounding=0
                rounding_power=0
              }

              device {
                name=epic-mouse-v1
                sensitivity=-0.500000
              }

              dwindle {
                preserve_split=true
                pseudotile=true
              }

              env=XCURSOR_SIZE,24
              env=HYPRCURSOR_SIZE,24
              env=HYPRCURSOR_THEME,rose-pine-hyprcursor

              general {
                allow_tearing=false
                border_size=1
                col.active_border=rgba(ff0000ff) rgba(ff8800ff) rgba(ffff00ff) rgba(00ff00ff) rgba(00ffffff) rgba(0000ffff) rgba(8800ffff) rgba(ff00ffff) 45deg
                col.inactive_border=rgba(ff0000ff) rgba(ff8800ff) rgba(ffff00ff) rgba(00ff00ff) rgba(00ffffff) rgba(0000ffff) rgba(8800ffff) rgba(ff00ffff) 45deg
                gaps_in=5
                gaps_out=5
                layout=dwindle
                resize_on_border=false
              }

              gesture=3, horizontal, workspace

              ${lib.optionalString config.isLaptop ''
                input {
                  touchpad {
                    natural_scroll=false
                  }
                  follow_mouse=1
                  kb_layout=us
                  sensitivity=0.000000
                }
              ''}

              master {
                new_status=master
              }

              misc {
                disable_hyprland_logo=true
                force_default_wallpaper=0
              }

              layerrule = blur on, ignore_alpha 0.2, match:namespace quickshell

              ${monitorConfiguration}
            '')
          ];
      };
    };
}
