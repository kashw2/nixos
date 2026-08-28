{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
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
