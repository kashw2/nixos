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
        settings = {
          logo = {
            type = "kitty-direct";
            source = "${./logo.png}";
          };
          modules = [
            "os"
            "kernel"
            "uptime"
            "packages"
            "shell"
            "de"
            "wm"
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
          ];
        };
      };
    };
}
