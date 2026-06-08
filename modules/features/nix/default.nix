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
            "nixos:Lqpfa0jP2r+0Il9VOzVqA5c8RT/uao/Vd4ncVW/qiUU="
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

      # Continuously push newly-built store paths to the media attic cache.
      # watch-store uses inotify on /nix/store, so anything a `nixos-rebuild`
      # or `colmena apply/build` realises locally is uploaded automatically.
      # Best-effort: if the cache is unreachable the service just retries and
      # never blocks a build.
      systemd.services.attic-watch-store = {
        description = "Push new Nix store paths to the media attic cache";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ config.nix.package ];
        serviceConfig = {
          ExecStart = "${
            inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client
          }/bin/attic watch-store nixos";
          # sops renders the client config (with the push token) to
          # /run/attic/config.toml; XDG_CONFIG_HOME=/run makes attic find it.
          Environment = [ "XDG_CONFIG_HOME=/run" ];
          Restart = "always";
          RestartSec = "10s";
        };
      };

    };
}
