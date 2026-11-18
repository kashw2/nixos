{ ... }:
{
  # Starts the desktop app with its loopback control server on, so
  # `photocraft-cli mcp --bridge 127.0.0.1:7878` can drive the live window.
  flake.wrappers.photocraft =
    {
      pkgs,
      wlib,
      ...
    }:
    let
      runtime = data: {
        inherit data;
        esc-fn = wlib.escapeShellArgWithEnv;
      };
    in
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.photocraft;
        envDefault = {
          PHOTOCRAFT_CONTROL_PORT = "7878";
          # Created (0600) on first launch; the MCP bridge reads the same file.
          PHOTOCRAFT_CONTROL_TOKEN_FILE = runtime "$HOME/.local/state/photocraft/control.token";
          PHOTOCRAFT_AUTOMATION_READ_ROOT = runtime "$HOME";
          PHOTOCRAFT_AUTOMATION_WRITE_ROOT = runtime "$HOME";
        };
      };
    };
}
