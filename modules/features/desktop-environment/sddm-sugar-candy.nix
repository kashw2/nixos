{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.sddm-sugar-candy = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "sddm-sugar-candy";
        version = "1.6";

        src = pkgs.fetchFromGitHub {
          owner = "Kangie";
          repo = "sddm-sugar-candy";
          rev = "v${finalAttrs.version}";
          hash = "sha256-p2d7I0UBP63baW/q9MexYJQcqSmZ0L5rkwK3n66gmqM=";
        };

        dontBuild = true;
        dontWrapQtApps = true;

        installPhase = ''
          mkdir -p $out/share/sddm/themes
          cp -aR $src $out/share/sddm/themes/sugar-candy
          substituteInPlace $out/share/sddm/themes/sugar-candy/theme.conf \
              --replace-fail "Mountain.jpg" "${./Background.jpg}"
        '';
      });
    };
}
