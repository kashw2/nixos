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
      nixpkgs.config = {
        allowUnfree = true;
        nvidia.acceptLicense = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      };

      nix = {
        package = inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.nix;
        optimise.automatic = true;
        gc.automatic = true;
        channel.enable = false; # All systems use flakes
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
        distributedBuilds = true;
        buildMachines =
          lib.optionals
            (builtins.elem config.networking.hostName [
              "home"
              "family"
              "media"
              "thinkpad"
              "laptop"
            ])
            [
              {
                hostName = "homelab.local";
                systems = [ "x86_64-linux" ];
                maxJobs = 16;
                supportedFeatures = [
                  "kvm"
                  "nixos-test"
                  "big-parallel"
                  "benchmark"
                ];
                protocol = "ssh-ng";
                sshUser = "keanu";
                sshKey = "/home/keanu/.ssh/id_ed25519";
              }
              {
                hostName = "macmini.local";
                systems = [
                  "aarch64-darwin"
                ];
                supportedFeatures = [
                  "apple-virt"
                  "benchmark"
                  "big-parallel"
                  "nixos-test"
                ];
                protocol = "ssh-ng";
                sshUser = "keanu";
                sshKey = "/home/keanu/.ssh/id_ed25519";
              }
              {
                hostName = "aarch64-build-box.nix-community.org";
                systems = [ "aarch64-linux" ];
                supportedFeatures = [
                  "kvm"
                  "nixos-test"
                  "big-parallel"
                  "benchmark"
                ];
                protocol = "ssh-ng";
                sshUser = "kashw2";
                sshKey = "/home/keanu/.ssh/id_ed25519";
              }
              {
                hostName = "darwin-build-box.nix-community.org";
                systems = [ "x86_64-darwin" ];
                supportedFeatures = [
                  "apple-virt"
                  "benchmark"
                  "big-parallel"
                  "nixos-test"
                ];
                protocol = "ssh-ng";
                sshUser = "kashw2";
                sshKey = "/home/keanu/.ssh/id_ed25519";
              }
            ];
      };
    };

}
