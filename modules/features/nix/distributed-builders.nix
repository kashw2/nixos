{ self, inputs, ... }:
{
  flake.nixosModules.distributedBuilds =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      nix.distributedBuilds = true;
    };
}
