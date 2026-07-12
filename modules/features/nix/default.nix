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
        allowUnfree = lib.mkForce true;
        nvidia.acceptLicense = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      };

      nix = {
        package = inputs.nix.packages.${pkgs.system}.default.override (prev: {
          nix-functional-tests = prev.nix-functional-tests.overrideAttrs {
            doCheck = false;
          };
        });
        gc.automatic = true;
        gc.options = "--delete-older-than 30d";
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
            "https://nix-community.cachix.org"
            "https://cache.numtide.com"
            # "http://100.116.38.8:8080/nixos"
          ];
          trusted-substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
            "https://cache.numtide.com"
            # "http://100.116.38.8:8080/nixos"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
          auto-optimise-store = true;
          connect-timeout = 5;
          download-attempts = 3;
          fallback = true;
          trusted-users = [
            "keanu"
            "kashw2"
            "@wheel"
          ];
        };
      };

    };
}
