{ ... }:
{
  # Control server on 7676 for `gridcraft-cli mcp --connect`; the CLI finds the app's token.
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
