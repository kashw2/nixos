{ ... }:
{
  # Control server on 7575 for `deckcraft-cli mcp --connect`.
  flake.wrappers.deckcraft =
    {
      pkgs,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.deckcraft;
        envDefault.DECKCRAFT_CONTROL_PORT = "7575";
      };
    };
}
