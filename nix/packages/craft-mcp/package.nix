{ ... }:
{
  # Starts a craft app on the first MCP call that needs it.
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.craft-mcp = pkgs.writers.writePython3Bin "craft-mcp" { flakeIgnore = [ "E501" ]; } (
        builtins.replaceStrings [ "@setsid@" ] [ (lib.getExe' pkgs.util-linux "setsid") ] (
          builtins.readFile ./craft-mcp.py
        )
      );
    };
}
