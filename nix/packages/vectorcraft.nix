{ ... }:
{
  # Starts the desktop app with its loopback control server on 7979, the port
  # a bare `vectorcraft-cli mcp` connects to (falling back to headless).
  flake.wrappers.vectorcraft =
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
        package = pkgs.vectorcraft;
        envDefault = {
          VECTORCRAFT_CONTROL_PORT = "7979";
          VECTORCRAFT_AUTOMATION_READ_ROOT = runtime "$HOME";
          VECTORCRAFT_AUTOMATION_WRITE_ROOT = runtime "$HOME";
        };
      };
    };
}
