{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      formatter = pkgs.nixfmt;

      devShells.default = pkgs.mkShell {
        packages = [
          inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
          pkgs.nix
          pkgs.nixfmt
          pkgs.deadnix
          pkgs.statix
        ];
      };
    };
}
