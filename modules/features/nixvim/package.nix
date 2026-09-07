{
  self,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    lib = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };

  config.flake.lib.mkNeovim =
    {
      pkgs,
      host ? { },
    }:
    inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
      inherit pkgs;
      module = {
        imports = [ self.nixvimModules.default ];
        inherit host;
      };
    };

  config.perSystem =
    { system, ... }:
    {
      packages.neovim = self.lib.mkNeovim {
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
}
