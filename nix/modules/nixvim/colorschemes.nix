{ self, inputs, ... }:
{
  config.flake.nixvimModules.colorschemes =
    { pkgs, lib, ... }:
    {
      colorschemes = {
        catppuccin = {
          enable = true;
          settings = {
            flavour = "mocha";
            color_overrides = {
              mocha = {
                mantle = "#090912";
                crust = "#10101A";
                base = "#0B0B14";
              };
            };
          };
        };
      };
    };
}
