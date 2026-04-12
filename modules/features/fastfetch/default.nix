{ self, inputs, ... }:
{
  flake.wrappers.fastfetch =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.fastfetch ];
      config = {
        package = pkgs.fastfetch.override {
          flashfetchSupport = true;
        };
        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          logo = {
            type = "auto";
            source = "${./logo.png}";
          };
          modules = [
            "title"
            "separator"
            "os"
            "host"
            "kernel"
            "uptime"
            "packages"
            "shell"
            "display"
            "de"
            "wm"
            "wmtheme"
            "theme"
            "icons"
            "font"
            "cursor"
            "terminal"
            "terminalfont"
            "cpu"
            "gpu"
            "memory"
            "swap"
            "disk"
            "localip"
            "battery"
            "poweradapter"
            "locale"
            "break"
            "colors"
          ];
        };
      };
    };
}
