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

      nixpkgs.overlays = [
        # fabric 3.2.3 pins invoke<3, so nixpkgs marks it broken against invoke
        # 3.x, which takes azure-cli down with it (`az webapp` imports fabric).
        # Upstream fixed it on main but hasn't cut a release:
        # https://github.com/fabric/fabric/issues/2376
        # Remove once nixpkgs ships a fabric release that supports invoke 3.
        (final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (_: pyPrev: {
              fabric = pyPrev.fabric.overridePythonAttrs (old: {
                patches = (old.patches or [ ]) ++ [
                  (final.fetchpatch {
                    name = "fabric-invoke-3-support.patch";
                    url = "https://github.com/fabric/fabric/commit/7fa309db9dd5dac69079c1fb83b6f579555f7d53.patch";
                    hash = "sha256-HxdV1XbsytBYOHV8WqcpKMpqGRkbXD/UlmAFSrmsFTg=";
                  })
                ];
                pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "invoke" ];
                meta = old.meta // {
                  broken = false;
                };
              });
            })
          ];
        })
      ];

      nix = {
        package = inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.default.override (prev: {
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
            "https://nix-community.cachix.org"
            "https://cache.numtide.com"
            # "http://100.116.38.8:8080/nixos"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
          auto-optimise-store = true;
          connect-timeout = 5;
          download-attempts = 3;
          fallback = true;
          trusted-users = [
            "keanu"
            "@wheel"
          ];
        };
      };

    };
}
