{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.desktopEnvironment =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.rose-pine-hyprcursor ];

      programs.hyprland = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.wrap {
          inherit (config) isLaptop isDesktop;
        };
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

      # Point security.wrappers.Hyprland at the compositor binary, not the start-hyprland watchdog.
      # Otherwise the setuid Hyprland wrapper execs start-hyprland, which execs a fork bomb.
      security.wrappers.Hyprland.source = lib.mkForce (
        lib.getExe' config.programs.hyprland.package "Hyprland"
      );

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        wlr.enable = true;
      };

      systemd.user.targets.hyprland-session = {
        description = "Hyprland compositor session";
        bindsTo = [ "graphical-session.target" ];
        before = [ "graphical-session.target" ];
      };

      programs.hyprlock = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
      };

      # graphic-desktop.nix in nixpkgs sets this to true and consumes 1.2GB of storage
      # It's primary usage is for TTS and is not something we'd require
      services.speechd.enable = false;

      services.upower.enable = config.isLaptop;

      # Boot straight into Hyprland: initial_session autologins once at boot,
      # and tuigreet is only shown after logging out.
      services.greetd =
        let
          # start-hyprland and Hyprland print their startup banner and logs to stdout,
          # which greetd wires to tty1, so they'd draw over the plymouth splash.
          # Send them to the journal instead.
          session = "${lib.getExe' config.systemd.package "systemd-cat"} --identifier=hyprland ${lib.getExe config.programs.hyprland.package}";
        in
        {
          enable = true;
          settings = {
            initial_session = {
              user = "keanu";
              command = session;
            };
            default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd '${session}'";
          };
        };

      # Hand the screen straight from the plymouth splash to Hyprland. greetd is
      # Type=idle upstream, which holds it back for up to 5s after plymouth quits.
      systemd.services.greetd.serviceConfig.Type = lib.mkForce "simple";
      # Leave the last splash frame on screen instead of dropping back to the
      # text console while Hyprland starts.
      systemd.services.plymouth-quit.serviceConfig.ExecStart = lib.mkIf config.boot.plymouth.enable [
        ""
        "-${lib.getExe' config.boot.plymouth.package "plymouth"} quit --retain-splash"
      ];

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    };
}
