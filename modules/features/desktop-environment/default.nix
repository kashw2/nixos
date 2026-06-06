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

      programs.hyprlock = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
      };

      # Used by quickshell on laptops for battery info and power profiles
      services.upower.enable = config.isLaptop;
      services.power-profiles-daemon.enable = config.isLaptop;

      services.displayManager.autoLogin = {
        enable = true;
        user = "keanu";
      };

      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        enableHidpi = true;
        theme = toString self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-sugar-candy;
        extraPackages = with pkgs.qt6; [
          qt5compat
          qtsvg
        ];
      };

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    };
}
