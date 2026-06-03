{ self, inputs, ... }:
{
  # Vendored from https://github.com/NixOS/nixpkgs/pull/493230.
  # Remove this file (and the adjacent patch) once that PR is merged and
  # `pkgs.shortcut-mcp-server` is available from nixpkgs.
  perSystem =
    { pkgs, ... }:
    {
      packages.shortcut-mcp-server = pkgs.buildNpmPackage (finalAttrs: {
        pname = "shortcut-mcp-server";
        version = "0.22.0";

        src = pkgs.fetchFromGitHub {
          owner = "useshortcut";
          repo = "mcp-server-shortcut";
          tag = "v0.22.0";
          hash = "sha256-ixIll7lYJcYVRSUhoil+Qx7yULxBaNzhDI71afuF/bs=";
        };

        npmDepsHash = "sha256-xhfbx9hWv5UKzUryJG0g7m3tpOSW4wxX4uNoiC23EhQ=";

        patches = [ ./remove-bun-dep.patch ];

        meta = {
          description = "MCP server for Shortcut";
          homepage = "https://github.com/useshortcut/mcp-server-shortcut";
          changelog = "https://github.com/useshortcut/mcp-server-shortcut/releases/tag/v${finalAttrs.version}";
          license = [ pkgs.lib.licenses.mit ];
          maintainers = [ pkgs.lib.maintainers.kashw2 ];
          mainProgram = "mcp-server-shortcut";
        };
      });
    };
}
