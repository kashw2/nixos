{ ... }:
{
  # Control server on 7979 for a bare `vectorcraft-cli mcp`.
  flake.wrappers.vectorcraft =
    {
      pkgs,
      lib,
      wlib,
      ...
    }:
    let
      runtime = data: {
        inherit data;
        esc-fn = wlib.escapeShellArgWithEnv;
      };
      root = "$HOME/Documents/Artcraft/vectorcraft";
    in
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.vectorcraft;
        envDefault = {
          VECTORCRAFT_CONTROL_PORT = "7979";
          VECTORCRAFT_AUTOMATION_READ_ROOT = runtime root;
          VECTORCRAFT_AUTOMATION_WRITE_ROOT = runtime root;
        };
        # App needs the root.
        runShell = [ ''${lib.getExe' pkgs.coreutils "mkdir"} -p "${root}"'' ];
      };
    };
}
