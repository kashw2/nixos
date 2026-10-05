{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.nix
          pkgs.nixfmt
          pkgs.deadnix
          pkgs.statix
        ];
      };
    };
}
