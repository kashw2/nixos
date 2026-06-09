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
        package = inputs.nix.packages.${pkgs.system}.default;
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
            "https://nix-community.cachix.org"
            "http://100.116.38.8:8080/nixos"
          ];
          trusted-substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
            "http://100.116.38.8:8080/nixos"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixos:OfYc0+Gd91P4GChe7uQz/4+rAQfMFiegVVnSwNFPPbQ="
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
