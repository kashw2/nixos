{ self, inputs, ... }:
{
  flake.nixosModules.nix =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {

      imports = [
        self.nixosModules.distributedBuilds
      ];

      nixpkgs.config = {
        allowUnfree = true;
        nvidia.acceptLicense = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      };

      nix = {
        package = inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.nix;
        optimise.automatic = true;
        gc.automatic = true;
        channel.enable = false; # All hosts use flakes
        extraOptions = ''
          warn-dirty = false
          !include ${config.sops.templates."nix-access-tokens".path}
        '';
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://cache.nixos.org/"
          ];
          trusted-substituters = [
            "https://cache.nixos.org/"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
          auto-optimise-store = true;
          trusted-users = [
            "keanu"
            "kashw2"
            "@wheel"
          ];
        };
      };

    };
}
