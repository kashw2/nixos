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
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
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
                ''hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })''
              else if config.isDesktop then
                ''
                  hl.monitor({ output = "DP-3",     mode = "1920x1080@60", position = "0x0",    scale = 1 })
                  hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })
                  hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
                  hl.workspace_rule({ workspace = "2", monitor = "DP-3",     default = true })
                  hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", default = true })
                  hl.workspace_rule({ workspace = "4", monitor = "DP-3",     default = true })
                ''
              else
                ''hl.monitor({ output = "", mode = "1920x1080@60", position = "0x0", scale = 1 })'';
          in
          [
            "--"
            "--config"
            (pkgs.writeText "hyprland.lua" ''
              hl.on("hyprland.start", function()
                hl.exec_cmd("${lib.getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")
                hl.exec_cmd("${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper}")
                hl.exec_cmd("${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hypridle}")
                hl.exec_cmd("${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprshade} auto")
                hl.exec_cmd("${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} store")
                hl.exec_cmd("${
                  lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kitty
                } --class kitty-nixosvi --directory ~/nixos vi")
                hl.exec_cmd("${
                  lib.getExe (
                    self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell.wrap {
                      inherit (config) isDesktop isLaptop;
                    }
                  )
                }")
                hl.exec_cmd("${lib.getExe pkgs.firefox-devedition}")
              end)

              hl.env("XCURSOR_SIZE",    "24")
              hl.env("HYPRCURSOR_SIZE", "24")
              hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")

              hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
              hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
              hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
              hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
              hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })

              hl.config({ animations = { enabled = true } })

              hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
              hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
              hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
              hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
              hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
              hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
              hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
              hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
              hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
              hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
              hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
              hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
              hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
              hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
              hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
              hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
              hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
              hl.animation({ leaf = "borderangle",   enabled = true, speed = 70,   bezier = "linear",       style = "loop" })

              hl.bind("CTRL + ALT + p", hl.dsp.exec_cmd([[${lib.getExe pkgs.grim} -g "$( ${lib.getExe pkgs.slurp} )" - | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}]]))
              hl.bind("INSERT",      hl.dsp.exec_cmd("${
                lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kitty
              }"))
              hl.bind("SUPER + M",   hl.dsp.exec_cmd("${
                lib.getExe (
                  self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell.wrap {
                    inherit (config) isDesktop isLaptop;
                  }
                )
              } ipc call applauncher toggle"))
              hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("${
                lib.getExe' inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland "hyprctl"
              } dispatch forcerendererreload"))
              hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
              hl.bind("SUPER + F12",     hl.dsp.exit())
              hl.bind("SUPER + S",       hl.dsp.window.float({ action = "toggle" }))
              hl.bind("SUPER + F",       hl.dsp.window.fullscreen())
              hl.bind("SUPER + P",       hl.dsp.window.pseudo())
              hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("${
                lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprshade
              } toggle blue-light-filter"))
              hl.bind("SUPER + left",    hl.dsp.focus({ direction = "left" }))
              hl.bind("SUPER + right",   hl.dsp.focus({ direction = "right" }))
              hl.bind("SUPER + up",      hl.dsp.focus({ direction = "up" }))
              hl.bind("SUPER + down",    hl.dsp.focus({ direction = "down" }))

              for i = 1, 10 do
                local key = i % 10
                hl.bind("SUPER + "       .. key, hl.dsp.focus({ workspace = i }))
                hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
              end

              hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
              hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

              ${lib.optionalString config.isLaptop ''
                hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
                hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
                hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, repeating = true })
                hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true, repeating = true })
                hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("${lib.getExe pkgs.brightnessctl} -e4 -n2 set 5%+"), { locked = true, repeating = true })
                hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${lib.getExe pkgs.brightnessctl} -e4 -n2 set 5%-"), { locked = true, repeating = true })
              ''}

              hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("${lib.getExe pkgs.playerctl} play-pause"), { locked = true })
              hl.bind("XF86AudioNext", hl.dsp.exec_cmd("${lib.getExe pkgs.playerctl} next"),       { locked = true })
              hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("${lib.getExe pkgs.playerctl} previous"),   { locked = true })
              hl.bind("XF86AudioStop", hl.dsp.exec_cmd("${lib.getExe pkgs.playerctl} stop"),       { locked = true })

              hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
              hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

              hl.config({
                decoration = {
                  active_opacity   = 1.0,
                  inactive_opacity = 1.0,
                  rounding         = 0,
                  rounding_power   = 0,
                  blur = {
                    enabled  = true,
                    passes   = 4,
                    size     = 6,
                    vibrancy = 0.1696,
                  },
                },
              })

              hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

              hl.config({ dwindle = { preserve_split = true } })

              hl.config({
                general = {
                  allow_tearing    = false,
                  border_size      = 1,
                  gaps_in          = 5,
                  gaps_out         = 5,
                  layout           = "dwindle",
                  resize_on_border = false,
                  col = {
                    active_border = {
                      colors = {
                        "rgba(ff0000ff)", "rgba(ff8800ff)", "rgba(ffff00ff)", "rgba(00ff00ff)",
                        "rgba(00ffffff)", "rgba(0000ffff)", "rgba(8800ffff)", "rgba(ff00ffff)",
                      },
                      angle = 45,
                    },
                    inactive_border = {
                      colors = {
                        "rgba(ff0000ff)", "rgba(ff8800ff)", "rgba(ffff00ff)", "rgba(00ff00ff)",
                        "rgba(00ffffff)", "rgba(0000ffff)", "rgba(8800ffff)", "rgba(ff00ffff)",
                      },
                      angle = 45,
                    },
                  },
                },
              })

              hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

              ${lib.optionalString config.isLaptop ''
                hl.config({
                  input = {
                    follow_mouse = 1,
                    kb_layout    = "us",
                    sensitivity  = 0.0,
                    touchpad = {
                      natural_scroll = false,
                    },
                  },
                })
              ''}

              hl.config({ master = { new_status = "master" } })

              hl.config({
                misc = {
                  disable_hyprland_logo   = true,
                  force_default_wallpaper = 0,
                },
              })

              hl.layer_rule({
                name  = "quickshell-blur",
                match = { namespace = "quickshell" },
                blur         = true,
                ignore_alpha = 0.2,
              })

              hl.window_rule({ name = "firefox-ws1",       match = { class = "^(firefox-devedition)$" },       workspace = "1 silent" })
              hl.window_rule({ name = "kitty-nixosvi-ws4", match = { class = "^(kitty-nixosvi)$" }, workspace = "4 silent" })
              hl.window_rule({ name = "slack-ws3",         match = { class = "^(Slack)$" },         workspace = "3 silent" })
              hl.window_rule({ name = "discord-ws3",       match = { class = "^(discord)$" },       workspace = "3 silent" })

              ${monitorConfiguration}
            '')
          ];
      };
    };
}
