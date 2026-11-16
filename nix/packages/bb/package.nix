{ ... }:
{
  flake.wrappers.bb =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config.package = pkgs.buildGoModule (finalAttrs: {
        pname = "bb";
        version = "0.1.0";

        src = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./go.mod
            ./go.sum
            (lib.fileset.fileFilter (file: file.hasExt "go") ./.)
          ];
        };

        vendorHash = "sha256-NbuvbsmNbz3aKdjyyfpkbi52yRhXl473j3LvAUDn3L8=";

        ldflags = [
          "-s"
          "-w"
          "-X main.version=${finalAttrs.version}"
        ];

        # The CLI and remote tests create throwaway git checkouts.
        nativeCheckInputs = [ pkgs.git ];

        passthru.tests.version = pkgs.testers.testVersion {
          package = finalAttrs.finalPackage;
          command = "bb --version";
          version = "bb ${finalAttrs.version}";
        };

        meta = {
          description = "Bitbucket Cloud pull requests from the command line and as MCP tools";
          maintainers = [ lib.maintainers.kashw2 ];
          mainProgram = "bb";
          platforms = lib.platforms.linux;
        };
      });
    };
}
