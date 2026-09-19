{ ... }:
{
  config.flake.nixvimModules.host =
    { pkgs, lib, ... }:
    {
      options.host = {
        isServer = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this neovim is built for a headless server.";
        };
        codestatsSetup = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the rendered codestats setup lua, or null when no API key is available.";
        };
        claudeCommand = lib.mkOption {
          type = lib.types.str;
          default = lib.getExe pkgs.claude-code;
          description = "Command claude-code.nvim launches.";
        };
      };
    };
}
