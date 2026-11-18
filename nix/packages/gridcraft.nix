{ ... }:
{
  # Starts the desktop app with its loopback control server on 7676, so
  # `gridcraft-cli mcp --connect 7676` can drive the live window. The app writes
  # the per-port token to $XDG_RUNTIME_DIR/gridcraft, where the CLI finds it.
  flake.wrappers.gridcraft =
    {
      pkgs,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.gridcraft;
        envDefault.GRIDCRAFT_CONTROL_PORT = "7676";
      };
    };
}
