{ ... }:
{
  # Starts the desktop app with its loopback control server on 7575, so
  # `deckcraft-cli mcp --connect 7575` can drive the live window.
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
